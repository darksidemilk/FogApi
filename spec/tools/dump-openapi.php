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

if ('' === $web || !is_dir($web . '/lib/fog')) {
    fwrite(
        STDERR,
        "usage: php dump-openapi.php --web /path/to/packages/web"
        . " [--version X] [--out FILE]\n"
    );
    exit(2);
}

define('DS', DIRECTORY_SEPARATOR);
define('BASEPATH', $web);
define('FOG_VERSION', $version);
// Only read by code paths this script does not reach, but defined so that a
// stray reference is a wrong value rather than a fatal.
define('FOG_WEB_ROOT', '/fog/');

/*
 * gettext, when the extension is not loaded.
 *
 * openapi.class.php wraps its prose in _() 126 times, and FOG gets that
 * function from the gettext extension -- commons/init.php calls
 * bindtextdomain() and there is no PHP-level fallback anywhere in the tree.
 * A PHP built without gettext therefore fatals on the first description
 * string ("Call to undefined function FOG\_()"), which is a confusing way to
 * be told an extension is missing.
 *
 * Returning the msgid unchanged is not an approximation, it is what gettext
 * itself does when no domain is bound -- and this script deliberately binds
 * none, because the snapshot is the untranslated English document that the
 * generators read. Requiring the extension would buy nothing and would make
 * the tool refuse to run on stock PHP, CI included.
 *
 * Guarded, so a PHP that does have gettext keeps the real one rather than
 * fataling on a duplicate declaration.
 */
if (!function_exists('_')) {
    function _($message)
    {
        return $message;
    }
}

/*
 * Composer's autoloader, when the checkout has one.
 *
 * FOGProject/fogproject#1415 moved the core classes to PSR-4 under src/ --
 * FOGBase is src/Base/FOGBase.php now, not lib/fog/fogbase.class.php -- and
 * without this the dump stops at the first class it needs:
 *
 *   FAIL: ReflectionException: Class "FOG\FOGBase" does not exist
 *
 * vendor/ is committed upstream, so requiring it needs no composer install.
 * Loaded first, but it does not replace the index below: PSR-4 is
 * case-sensitive and OpenAPI asks for route classes by their lowercase route
 * name, so the bridging autoloader is still what answers 'host'.
 */
if (is_file($web . '/vendor/autoload.php')) {
    require_once $web . '/vendor/autoload.php';
}

/**
 * Indexes every class file by its lowercased basename.
 *
 * The same key the shipped autoloader uses, which matters because OpenAPI
 * asks for route classes by their lowercase route name ('host', not 'Host').
 *
 * Covers both layouts. lib/ holds *.class.php on older checkouts; src/ holds
 * PSR-4 names post-#1415. Indexing both means one script reads either, and a
 * checkout mid-migration with classes in both places still resolves.
 */
$index = [];
foreach (
    ['/lib/fog', '/lib/router', '/lib/db', '/lib/service', '/src'] as $dir
) {
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
        $matched = false;
        foreach (['.class.php', '.event.php', '.hook.php', '.report.php'] as $ext) {
            if (substr($name, -strlen($ext)) === $ext) {
                $index[strtolower(substr($name, 0, -strlen($ext)))]
                    = $file->getPathname();
                $matched = true;
            }
        }
        // PSR-4 names carry no marker suffix: src/Base/FOGBase.php, not
        // fogbase.class.php. Indexed only when a suffixed pattern did not
        // already claim the name, so a lib/ file still wins where both
        // layouts are present.
        if (!$matched && substr($name, -4) === '.php') {
            $key = strtolower(substr($name, 0, -4));
            if (!isset($index[$key])) {
                $index[$key] = $file->getPathname();
            }
        }
    }
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

try {
    // $HookManager and $EventManager are protected statics on FOGBase, set by
    // LoadGlobals during a real boot. There is no boot here.
    $base = new ReflectionClass('FOG\FOGBase');
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
    \FOG\FOGBase::$httpproto = 'https';
    \FOG\FOGBase::$httphost = 'fog.example.invalid';

    $document = \FOG\OpenAPI::document();
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
