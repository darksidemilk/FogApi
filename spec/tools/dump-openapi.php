<?php
/**
 * Produces FOG's own OpenAPI document from a fogproject checkout, with no
 * server, no database and no configuration.
 *
 * FOG 1.6 serves this document from GET {webroot}/system/openapi (and the
 * /swagger.json alias), built per request so that it describes the classes
 * THIS server exposes, plugin contributions included. That is the right
 * design for a server and the wrong one for a code generator: generating
 * FogApi's cmdlets has to be reproducible from a commit, reviewable as a
 * diff, and possible on a machine that has no FOG server on it.
 *
 * So the snapshot in spec/openapi/ is produced by this script instead of by
 * curl, and OpenAPI::document() is called directly rather than reimplemented.
 * Nothing here describes the API; it only supplies the four things the
 * generator reads that a checkout does not have lying around.
 *
 * It works at all because building the document touches no data. Route's
 * class lists are literal static arrays, the per-class field maps come from
 * ReflectionClass::getDefaultProperties() (which never instantiates), the
 * column types come from commons/schema-expected.php, and defining a PHP
 * class has no side effects. The database is reached only by methods nothing
 * here calls.
 *
 * Differences from a live document, all of them deliberate:
 *
 *   - info.version is the string passed to --version (default 'snapshot'),
 *     because FOG_VERSION is stamped at install time and a checkout has none.
 *   - servers[0].url is a placeholder host. A client reads its own base URL
 *     from its settings, not from here.
 *   - No plugin hooks fire, so the document covers the classes FOG ships
 *     with. That is the correct baseline for generated cmdlets; plugin
 *     classes are a runtime discovery concern (see Get-FogApiSpec) and not
 *     something to bake into a shipped module.
 *
 * Usage:
 *   php dump-openapi.php --web /path/to/fogproject/packages/web \
 *                        [--version 1.6.0] [--out spec/openapi/fog-1.6.json]
 *
 * Exit status 0 on success, 2 on bad usage, 1 on generation failure.
 */

// Single colons throughout: PHP's getopt() accepts `--opt value` only for a
// required-argument long option. With `::` it would take `--opt=value` alone
// and hand back false for `--opt value`, which reads as "given but empty".
$opts = getopt('', ['web:', 'version:', 'out:']);
$web = rtrim((string)($opts['web'] ?? ''), '/');
$version = (string)($opts['version'] ?? 'snapshot');
$out = (string)($opts['out'] ?? '');

// Two layouts, because the server moved under us. Core became Composer-native
// PSR-4 under packages/web/src/ on working-1.6 (FOGProject/fogproject #1421
// and the bucket move after it), and lib/fog, lib/router, lib/db and
// lib/service no longer exist there. An older checkout still has them, and a
// snapshot may legitimately need regenerating from one, so both are supported
// and the layout is detected rather than configured.
$psr4 = is_dir($web . '/src');

if ('' === $web || (!$psr4 && !is_dir($web . '/lib/fog'))) {
    fwrite(
        STDERR,
        "usage: php dump-openapi.php --web /path/to/packages/web"
        . " [--version X] [--out FILE]\n"
        . "  (expected either <web>/src or <web>/lib/fog to exist)\n"
    );
    exit(2);
}

define('DS', DIRECTORY_SEPARATOR);
define('BASEPATH', $web);
define('FOG_VERSION', $version);
// Only read by code paths this script does not reach, but defined so that a
// stray reference is a wrong value rather than a fatal.
define('FOG_WEB_ROOT', '/fog/');

/**
 * Indexes every class file by its lowercased basename.
 *
 * The same key the shipped autoloader uses, which matters because OpenAPI
 * asks for route classes by their lowercase route name ('host', not 'Host').
 */
$index = [];
foreach (['/lib/fog', '/lib/router', '/lib/db', '/lib/service'] as $dir) {
    if (!is_dir($web . $dir)) {
        continue;
    }
    $walk = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator(
            $web . $dir,
            FilesystemIterator::SKIP_DOTS
        )
    );
    foreach ($walk as $file) {
        if (!$file->isFile()) {
            continue;
        }
        $name = $file->getFilename();
        foreach (['.class.php', '.event.php', '.hook.php', '.report.php'] as $ext) {
            if (substr($name, -strlen($ext)) === $ext) {
                $index[strtolower(substr($name, 0, -strlen($ext)))]
                    = $file->getPathname();
            }
        }
    }
}

// PSR-4 checkout: load commons/init.php. Composer's own autoloader is NOT
// enough on its own, and the way it fails is the reason this is spelled out.
//
// OpenAPI asks for route classes by their lowercase route name ('host'), and
// FOGBase::qualify() turns that into FOG\Items\Host by consulting
// Initiator::srcClassMap(). With Composer alone, Initiator does not exist, so
// every qualify() raises Error -- which OpenAPI::_classVars() CATCHES, because
// that catch is there to stop one broken plugin taking the document down. The
// result is a document that builds successfully with every per-class path and
// schema silently missing: 16 paths and 50KB instead of 200-odd and 1.3MB.
// A wrong snapshot that looks like a right one.
//
// Requiring init.php costs almost nothing. Its only file-scope side effect is
// requiring vendor/autoload.php; everything else in it is class definitions.
// FOG is booted by LoadGlobals, which is not called here, so the "no server,
// no database" property in the header still holds.
if ($psr4) {
    $autoload = $web . '/vendor/autoload.php';
    if (!is_file($autoload)) {
        fwrite(
            STDERR,
            "FAIL: $autoload not found. A PSR-4 checkout needs its vendor/\n"
            . "  directory; run `composer install` in $web.\n"
        );
        exit(1);
    }

    // Initiator caches its src/ map under FOG_CACHE_DIR. Pointed at a scratch
    // directory unconditionally: on a machine that also RUNS FOG, the default
    // would be a live server's cache, and a generator must never write there.
    $scratch = sys_get_temp_dir() . '/fogapi-dump-' . getmypid();
    @mkdir($scratch, 0700, true);
    define('FOG_CACHE_DIR', $scratch);
    define('FOG_LOG_DIR', $scratch);
    define('FOG_PLUGIN_DIR', $scratch);
    register_shutdown_function(
        function () use ($scratch) {
            foreach ((array)glob($scratch . '/*') as $f) {
                @unlink($f);
            }
            @rmdir($scratch);
        }
    );

    $init = $web . '/commons/init.php';
    if (!is_file($init)) {
        fwrite(STDERR, "FAIL: $init not found\n");
        exit(1);
    }
    require $init;
}

spl_autoload_register(
    function ($class) use ($index) {
        // Answers for 'Host', 'FOG\Host' and 'host' alike. Split rather than
        // strrpos: strrpos returns false for an un-namespaced name and
        // (int)false + 1 would silently eat the first character, which shows
        // up as every class being absent.
        $parts = explode('\\', $class);
        $short = strtolower(end($parts));
        if (!isset($index[$short])) {
            return;
        }
        require_once $index[$short];
        // The files declare `namespace FOG;`, so a lookup by the bare route
        // name needs bridging to the namespaced class, and vice versa.
        foreach (["FOG\\$short", $short] as $candidate) {
            if (class_exists($candidate, false)
                && !class_exists($class, false)
            ) {
                class_alias($candidate, $class);
                return;
            }
        }
    }
);

/**
 * A hook manager that fires nothing.
 *
 * Route::sensitiveFieldMap() and serverOwnedFields() fire hooks so a plugin
 * can amend the field lists. A checkout has no plugins, so firing nothing is
 * the honest answer and is what a stock server produces. The gap between this
 * and a live document is exactly the plugin contributions, which is a gap
 * worth leaving visible rather than papering over.
 */
class OfflineHookManager
{
    /**
     * @param string $event The event name.
     * @param array  $args  The event arguments, by reference in the real one.
     *
     * @return void
     */
    public function processEvent($event, $args = [])
    {
    }

    /**
     * @param string   $event    The event name.
     * @param callable $callable The listener.
     *
     * @return void
     */
    public function register($event, $callable)
    {
    }

    /**
     * @param string $name The method called.
     * @param array  $args Its arguments.
     *
     * @return null
     */
    public function __call($name, $args)
    {
        return null;
    }
}

// The bucket move put these under FOG\Base and FOG\Router; before it they
// were flat FOG\. Resolved rather than hardcoded so one script serves both
// layouts, and named explicitly so a missing class fails here with a clear
// message instead of somewhere inside the document build.
$fogBaseClass = class_exists('FOG\Base\FOGBase')
    ? 'FOG\Base\FOGBase'
    : 'FOG\FOGBase';
$openApiClass = class_exists('FOG\Router\OpenAPI')
    ? 'FOG\Router\OpenAPI'
    : 'FOG\OpenAPI';

foreach ([$fogBaseClass, $openApiClass] as $needed) {
    if (!class_exists($needed)) {
        fwrite(STDERR, "FAIL: $needed did not load from $web\n");
        exit(1);
    }
}

try {
    // $HookManager and $EventManager are protected statics on FOGBase, set by
    // LoadGlobals during a real boot. There is no boot here.
    $base = new ReflectionClass($fogBaseClass);
    foreach (['HookManager', 'EventManager'] as $name) {
        if (!$base->hasProperty($name)) {
            continue;
        }
        $prop = $base->getProperty($name);
        $prop->setAccessible(true);
        $prop->setValue(null, new OfflineHookManager());
    }

    // servers[0].url is built from these. A placeholder rather than a real
    // host, so a snapshot cannot be mistaken for a description of somebody's
    // actual server.
    $fogBaseClass::$httpproto = 'https';
    $fogBaseClass::$httphost = 'fog.example.invalid';

    $document = $openApiClass::document();
} catch (\Throwable $e) {
    fwrite(
        STDERR,
        sprintf(
            "FAIL: %s: %s\n  at %s:%d\n",
            get_class($e),
            $e->getMessage(),
            $e->getFile(),
            $e->getLine()
        )
    );
    exit(1);
}

// Every routed class must have produced at least one path.
//
// This is not defensiveness for its own sake. OpenAPI::_classVars() wraps its
// class lookup in `catch (\Error)` so that one broken plugin cannot take the
// whole document down -- correct for a live server, and on this side it means
// a class that fails to resolve is silently DROPPED rather than reported. The
// document still builds, still validates, and still writes.
//
// That is exactly what happened when core moved to PSR-4 and this script was
// still autoloading by basename: 16 paths and 50KB where there should have
// been 380 and 1.3MB, written with exit status 0 and a cheerful summary line.
// A snapshot that is quietly missing 95% of the API is worse than no snapshot,
// because it is a plausible input to every generator downstream of it.
//
// The baseline has to come from OUTSIDE the document. The document's own `tags`
// are emitted from the same resolved-class loop the paths are, so a dropped
// class loses its tag as well and a tags-vs-paths check is self-consistent on
// exactly the input it is supposed to reject -- verified: it passed the 16-path
// document. Route::$validClasses is the router's own list, a plain array of
// strings that needs no qualify() and so cannot be thinned by the failure being
// tested for.
$routeClass = class_exists('FOG\Router\Route') ? 'FOG\Router\Route' : 'FOG\Route';
$expected = [];
if (class_exists($routeClass)) {
    $prop = new ReflectionProperty($routeClass, 'validClasses');
    $prop->setAccessible(true);
    $expected = (array) $prop->getValue();
}
if (count($expected) < 1) {
    fwrite(STDERR, "FAIL: could not read {$routeClass}::\$validClasses\n");
    exit(1);
}

$seen = [];
foreach (($document['paths'] ?? []) as $path => $ops) {
    foreach ($ops as $op) {
        foreach ((is_array($op) ? ($op['tags'] ?? []) : []) as $tag) {
            $seen[$tag] = true;
        }
    }
}
$missing = array_values(array_diff($expected, array_keys($seen)));
if (count($missing) > 0) {
    fwrite(
        STDERR,
        sprintf(
            "FAIL: %d of %d routed classes produced no paths: %s\n"
            . "  The document built, but those classes did not resolve. This is\n"
            . "  the silent-drop path in OpenAPI::_classVars(), not a real\n"
            . "  absence -- check that the autoloader above matches the layout\n"
            . "  of %s.\n",
            count($missing),
            count($expected),
            implode(', ', array_slice($missing, 0, 10))
                . (count($missing) > 10 ? ', ...' : ''),
            $web
        )
    );
    exit(1);
}

$json = json_encode(
    $document,
    JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
);
if (false === $json) {
    fwrite(STDERR, 'FAIL: ' . json_last_error_msg() . "\n");
    exit(1);
}
$json .= "\n";

if ('' === $out) {
    echo $json;
    exit(0);
}
if (false === file_put_contents($out, $json)) {
    fwrite(STDERR, "FAIL: could not write $out\n");
    exit(1);
}
fwrite(
    STDERR,
    sprintf(
        "wrote %s: %d paths, %d schemas, %d bytes\n",
        $out,
        count($document['paths']),
        count($document['components']['schemas']),
        strlen($json)
    )
);
exit(0);
