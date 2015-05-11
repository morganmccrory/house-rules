# Sprockets: Rack-based asset packaging

Sprockets is a Ruby library for compiling and serving web assets.
It features declarative dependency management for JavaScript and CSS
assets, as well as a powerful preprocessor pipeline that allows you to
write assets in languages like CoffeeScript, Sass and SCSS.


## Installation

Install Sprockets from RubyGems:

``` sh
$ gem install sprockets
```

Or include it in your project's `Gemfile` with Bundler:

``` ruby
gem 'sprockets', '~> 3.0'
```


## Understanding the Sprockets Environment

You'll need an instance of the `Sprockets::Environment` class to
access and serve assets from your application. Under Rails 4.0 and
later, `YourApp::Application.assets` is a preconfigured
`Sprockets::Environment` instance. For Rack-based applications, create
an instance in `config.ru`.

The Sprockets `Environment` has methods for retrieving and serving
assets, manipulating the load path, and registering processors. It is
also a Rack application that can be mounted at a URL to serve assets
over HTTP.

### The Load Path

The *load path* is an ordered list of directories that Sprockets uses
to search for assets.

In the simplest case, a Sprockets environment's load path will consist
of a single directory containing your application's asset source
files. When mounted, the environment will serve assets from this
directory as if they were static files in your public root.

The power of the load path is that it lets you organize your source
files into multiple directories -- even directories that live outside
your application -- and combine those directories into a single
virtual filesystem. That means you can easily bundle JavaScript, CSS
and images into a Ruby library or [Bower](http://bower.io) package and import them into your application.

#### Manipulating the Load Path

To add a directory to your environment's load path, use the
`append_path` and `prepend_path` methods. Directories at the beginning
of the load path have precedence over subsequent directories.

``` ruby
environment = Sprockets::Environment.new
environment.append_path 'app/assets/javascripts'
environment.append_path 'lib/assets/javascripts'
environment.append_path 'vendor/assets/bower_components'
```

In general, you should append to the path by default and reserve
prepending for cases where you need to override existing assets.

### Accessing Assets

Once you've set up your environment's load path, you can mount the
environment as a Rack server and request assets via HTTP. You can also
access assets programmatically from within your application.

#### Logical Paths

Assets in Sprockets are always referenced by their *logical path*.

The logical path is the path of the asset source file relative to its
containing directory in the load path. For example, if your load path
contains the directory `app/assets/javascripts`:

<table>
  <tr>
    <th>Asset source file</th>
    <th>Logical path</th>
  </tr>
  <tr>
    <td>app/assets/javascripts/application.js</td>
    <td>application.js</td>
  </tr>
  <tr>
    <td>app/assets/javascripts/models/project.js</td>
    <td>models/project.js</td>
  </tr>
</table>

In this way, all directories in the load path are merged to create a
virtual filesystem whose entries are logical paths.

#### Serving Assets Over HTTP

When you mount an environment, all of its assets are accessible as
logical paths underneath the *mount point*. For example, if you mount
your environment at `/assets` and request the URL
`/assets/application.js`, Sprockets will search your load path for the
file named `application.js` and serve it.

Under Rails 4.0 and later, your Sprockets environment is automatically
mounted at `/assets`. If you are using Sprockets with a Rack
application, you will need to mount the environment yourself. A good
way to do this is with the `map` method in `config.ru`:

``` ruby
require 'sprockets'
map '/assets' do
  environment = Sprockets::Environment.new
  environment.append_path 'app/assets/javascripts'
  environment.append_path 'app/assets/stylesheets'
  run environment
end

map '/' do
  run YourRackApp
end
```

#### Accessing Assets Programmatically

You can use the `find_asset` method (aliased as `[]`) to retrieve an
asset from a Sprockets environment. Pass it a logical path and you'll
get a `Sprockets::Asset` instance back:

``` ruby
environment['application.js']
# => #<Sprockets::Asset ...>
```

Call `to_s` on the resulting asset to access its contents, `length` to
get its length in bytes, `mtime` to query its last-modified time, and
`filename` to get its full path on the filesystem.


## Using Processors

Asset source files can be written in another format, like SCSS or
CoffeeScript, and automatically compiled to CSS or JavaScript by
Sprockets. Processors that convert a file from one format to another are called *transformers*.

### Minifying Assets

Several JavaScript and CSS minifiers are available through shorthand.

``` ruby
environment.js_compressor  = :uglify
environment.css_compressor = :scss
```

### Styling with Sass and SCSS

[Sass](http://sass-lang.com/) is a language that compiles to CSS and
adds features like nested rules, variables, mixins and selector
inheritance.

If the `sass` gem is available to your application, you can use Sass
to write CSS assets in Sprockets.

Sprockets supports both Sass syntaxes. For the original
whitespace-sensitive syntax, use the extension `.sass`. For the
new SCSS syntax, use the extension `.scss`.

### Scripting with CoffeeScript

[CoffeeScript](http://jashkenas.github.com/coffee-script/) is a
language that compiles to the "good parts" of JavaScript, featuring a
cleaner syntax with array comprehensions, classes, and function
binding.

If the `coffee-script` gem is available to your application, you can
use CoffeeScript to write JavaScript assets in Sprockets. Note that
the CoffeeScript compiler is written in JavaScript, and you will need
an [ExecJS](https://github.com/rails/execjs)-supported runtime
on your system to invoke it.

To write JavaScript assets with CoffeeScript, use the extension
`.coffee`.

### JavaScript Templating with EJS and Eco

Sprockets supports *JavaScript templates* for client-side rendering of
strings or markup. JavaScript templates have the special format
extension `.jst` and are compiled to JavaScript functions.

When loaded, a JavaScript template function can be accessed by its
logical path as a property on the global `JST` object. Invoke a
template function to render the template as a string. The resulting
string can then be inserted into the DOM.

```
<!-- templates/hello.jst.ejs -->
<div>Hello, <span><%= name %></span>!</div>

// application.js
//= require templates/hello
$("#hello").html(JST["templates/hello"]({ name: "Sam" }));
```

Sprockets supports two JavaScript template languages:
[EJS](https://github.com/sstephenson/ruby-ejs), for embedded
JavaScript, and [Eco](https://github.com/sstephenson/ruby-eco), for
embedded CoffeeScript. Both languages use the familiar `<% … %>`
syntax for embedding logic in templates.

If the `ejs` gem is available to your application, you can use EJS
templates in Sprockets. EJS templates have the extension `.jst.ejs`.

If the `eco` gem is available to your application, you can use [Eco
templates](https://github.com/sstephenson/eco) in Sprockets. Eco
templates have the extension `.jst.eco`. Note that the `eco` gem
depends on the CoffeeScript compiler, so the same caveats apply as
outlined above for the CoffeeScript engine.

### Invoking Ruby with ERB

Sprockets provides an ERB engine for preprocessing assets using
embedded Ruby code. Append `.erb` to a CSS or JavaScript asset's
filename to enable the ERB engine.

Ruby code embedded in an asset is evaluated in the context of a
`Sprockets::Context` instance for the given asset. Common uses for ERB
include:

- embedding another asset as a Base64-encoded `data:` URI with the
  `asset_data_uri` helper
- inserting the URL to another asset, such as with the `asset_path`
  helper provided by the Sprockets Rails plugin
- embedding other application resources, such as a localized string
  database, in a JavaScript asset via JSON
- embedding version constants loaded from another file

See the [Helper Methods](lib/sprockets/context.rb) section for more information about
interacting with `Sprockets::Context` instances via ERB.


## Managing and Bundling Dependencies

You can create *asset bundles* -- ordered concatenations of asset
source files -- by specifying dependencies in a special comment syntax
at the top of each source file.

Sprockets reads these comments, called *directives*, and processes
them to recursively build a dependency graph. When you request an
asset with dependencies, the dependencies will be included in order at
the top of the file.

### The Directive Processor

Sprockets runs the *directive processor* on each CSS and JavaScript
source file. The directive processor scans for comment lines beginning
with `=` in comment blocks at the top of the file.

``` js
//= require jquery
//= require jquery-ui
//= require backbone
//= require_tree .
```

The first word immediately following `=` specifies the directive
name. Any words following the directive name are treated as
arguments. Arguments may be placed in single or double quotes if they
contain spaces, similar to commands in the Unix shell.

**Note**: Non-directive comment lines will be preserved in the final
  asset, but directive comments are stripped after
  processing. Sprockets will not look for directives in comment blocks
  that occur after the first line of code.

#### Supported Comment Types

The directive processor understands comment blocks in three formats:

``` css
/* Multi-line comment blocks (CSS, SCSS, JavaScript)
 *= require foo
 */
```

``` js
// Single-line comment blocks (SCSS, JavaScript)
//= require foo
```

``` coffee
# Single-line comment blocks (CoffeeScript)
#= require foo
```

### Sprockets Directives

You can use the following directives to declare dependencies in asset
source files.

For directives that take a *path* argument, you may specify either a
logical path or a relative path. Relative paths begin with `./` and
reference files relative to the location of the current file.

#### The `require` Directive

`require` *path* inserts the contents of the asset source file
specified by *path*. If the file is required multiple times, it will
appear in the bundle only once.

### The `require_directory` Directive ###

`require_directory` *path* requires all source files of the same
format in the directory specified by *path*. Files are required in
alphabetical order.

#### The `require_tree` Directive

`require_tree` *path* works like `require_directory`, but operates
recursively to require all files in all subdirectories of the
directory specified by *path*.

#### The `require_self` Directive

`require_self` tells Sprockets to insert the body of the current
source file before any subsequent `require` directives.

#### The `link` Directive

`link` *path* declares a dependency on the target *path* and adds it to a list
of subdependencies to automatically be compiled when the asset is written out to
disk.

For an example, in a CSS file you might reference an external image that always
needs to be compiled along with the css file.

``` css
/*= link "logo.png" */
.logo {
  background-image: url(logo.png)
}
```

However, if you use a `asset-path` or `asset-url` SCSS helper, these links will
automatically be defined for you.

``` css
.logo {
  background-image: asset-url("logo.png")
}
```

#### The `depend_on` Directive

`depend_on` *path* declares a dependency on the given *path* without
including it in the bundle. This is useful when you need to expire an
asset's cache in response to a change in another file.

#### The `depend_on_asset` Directive

`depend_on_asset` *path* works like `depend_on`, but operates
recursively reading the file and following the directives found. This is automatically implied if you use `link`, so consider if it just makes sense using `link` instead of `depend_on_asset`.

#### The `stub` Directive

`stub` *path* allows dependency to be excluded from the asset bundle.
The *path* must be a valid asset and may or may not already be part
of the bundle. `stub` should only be used at the top level bundle, not
within any subdependencies.


## Processor Interface

Sprockets 2.x was originally design around [Tilt](https://github.com/rtomayko/tilt)'s engine interface. However, starting with 3.x, a new interface has been introduced deprecating Tilt.

Similar to Rack, a processor is a any "callable" (an object that responds to `call`). This maybe a simple Proc or a full class that defines a `def self.call(input)` method. The `call` method accepts an `input` Hash and returns a Hash of metadata.

Also see [`Sprockets::ProcessorUtils`](https://github.com/rails/sprockets/blob/master/lib/sprockets/processor_utils.rb) for public helper methods.

### input Hash

The `input` Hash defines the following public fields.

* `:data` - String asset contents
* `:environment` - Current `Sprockets::Environment` instance.
* `:cache` - A `Sprockets::Cache` instance. See [`Sprockets::Cache#fetch`](https://github.com/rails/sprockets/blob/master/lib/sprockets/cache.rb).
* `:uri` - String Asset URI.
* `:filename` - String full path to original file.
* `:load_path` - String current load path for filename.
* `:name` - String logical path for filename.
* `:content_type` - String content type of the output asset.
* `:metadata` - Hash of processor metadata.

``` ruby
def self.call(input)
  input[:cache].fetch("my:cache:key:v1") do
    # Remove all semicolons from source
    input[:data].gsub(";", "")
  end
end
```

### return Hash

The processor should return metadata `Hash`. With the exception of the `:data` key, the processor can store arbitrary JSON valid values in this Hash. The data will be stored and exposed on `Asset#metadata`.

The returned `:data` replaces the assets `input[:data]` to the next processor in the chain. Returning a `String` is shorthand for returning `{ data: str }`. And returning `nil` is shorthand for a no-op where the input data is not transformed, `{ data: input[:data] }`.

### metadata

The metadata Hash provides an open format for processors to extend the pipeline processor. Internally, built-in processors use it for passing data to each other.

* `:required` - A `Set` of String Asset URIs that the Bundle processor should concatenate together.
* `:stubbed` - A `Set` of String Asset URIs that will be omitted from the `:required` set.
* `:links` - A `Set` of String Asset URIs that should be compiled along with this asset.
* `:dependencies` - A `Set` of String Cache URIs that should be monitored for caching.

``` ruby
def self.call(input)
  # Any metadata may start off as nil, so initialize it the value
  required = Set.new(input[:metadata][:required])

  # Manually add "foo.js" asset uri to our bundle
  required << input[:environment].resolve("foo.js")

  { required: required }
end
```


## Development

### Contributing

The Sprockets source code is [hosted on
GitHub](https://github.com/rails/sprockets). You can check out a
copy of the latest code using Git:

    $ git clone https://github.com/rails/sprockets

If you've found a bug or have a question, please open an issue on the
[Sprockets issue
tracker](https://github.com/rails/sprockets/issues). Or, clone
the Sprockets repository, write a failing test case, fix the bug and
submit a pull request.

### Version History

**3.0.1** (April 14, 2015)

* Fixed `Context#depend_on` with paths outside the load path

**3.0.0** (April 12, 2015)

* New processor API. Tilt interface is deprecated.
* Improved file store caching backend.
* MIME Types now accept charset custom charset detecters. Improves support for UTF-16/32 files.
* Environment#version no longer affects asset digests. Only used for busting the asset cache.
* Removed builtin support for LESS.
* Removed `//= include` directive support.
* Deprecated `BundledAsset#to_a`. Use `BundledAsset#included` to access debugging subcomponents.
* Support circular dependencies. For parity with ES6 modules.
* Manifest compilation will no longer generate .gz files by default. [Mixing
  Content-Encoding and ETags is just a bad
  idea](https://issues.apache.org/bugzilla/show_bug.cgi?id=39727)
* Added linked or referenced assets. When an asset is compiled, any of its links will be compiled as well.
* Introduce some limitations around enumerating all logical paths. 4.x will deprecate it and favor linked manifests for compliation.
* Add Asset integrity attribute for Subresource Integrity
* Default digest changed to SHA256. Configuring `digest_class` is deprecated.
* Rename `Asset#digest` to `Asset#hexdigest`. `Asset#digest` is deprecated and will
  return a raw byte String in 4.x.
* Added transitional compatibility flag to `Environment#resolve(path, compat: true)`. 2.x mode operates with `compat: true` and 4.x with `compat: false`
* `manifest-abc123.json` renamed to `.sprockets-abc123.json`

**2.12.3** (October 28, 2014)

* Security: Fix directory traversal bug in development mode server.

**2.12.2** (September 5, 2014)

* Ensure internal asset lookups calls are still restricted to load paths within
  asset compiles. Though, you should not depend on internal asset resolves to be
  completely restricted for security reasons. Assets themselves should be
  considered full scripting environments with filesystem access.

**2.12.1** (April 17, 2014)

* Fix making manifest target directory when its different than the output directory.

**2.12.0** (March 13, 2014)

* Avoid context reference in SassImporter hack so its Marshallable. Fixes
 issues with Sass 3.3.x.

**2.11.0** (February 19, 2014)

* Cache store must now be an LRU implementation.
* Default digest changed to SHA1. To continue using MD5.
  `env.digest_class = Digest::MD5`.

**2.10.0** (May 24, 2013)

* Support for `bower.json`

**2.9.3** (April 20, 2013)

* Fixed sass caching bug

**2.9.2** (April 8, 2013)

* Improve file freshness check performance
* Directive processor encoding fixes

**2.9.1** (April 6, 2013)

* Support for Uglifier 2.x

**2.9.0** (February 25, 2013)

* Write out gzipped variants of bundled assets.

**2.8.2** (December 10, 2012)

* Fixed top level Sass constant references
* Fixed manifest logger when environment is disabled

**2.8.1** (October 31, 2012)

* Fixed Sass importer bug

**2.8.0** (October 16, 2012)

* Allow manifest location to be separated from output directory
* Pass logical path and absolute path to each_logical_path iterator

**2.7.0** (October 10, 2012)

* Added --css-compressor and --js-compressor command line flags
* Added css/js compressor shorthand
* Change default manifest.json filename to be a randomized manifest-16HEXBYTES.json
* Allow nil environment to be passed to manifest
* Allow manifest instance to be set on rake task

**2.6.0** (September 19, 2012)

* Added bower component.json require support

**2.5.0** (September 4, 2012)

* Fixed Ruby 2.0 RegExp warning
* Provide stubbed implementation of context *_path helpers
* Add SassCompressor

**2.4.5** (July 10, 2012)

* Tweaked some logger levels

**2.4.4** (July 2, 2012)

* Canonicalize logical path extensions
* Check absolute paths passed to depend_on

**2.4.3** (May 16, 2012)

* Exposed :sprockets in sass options
* Include dependency paths in asset mtime

**2.4.2** (May 7, 2012)

* Fixed MultiJson feature detect

**2.4.1** (April 26, 2012)

* Fixed MultiJson API change
* Fixed gzip mtime

**2.4.0** (March 27, 2012)

* Added global path registry
* Added global processor registry

**2.3.2** (March 26, 2012)

* Fix Context#logical_path with dots

**2.3.1** (February 11, 2012)

* Added bytesize to manifest
* Added Asset#bytesize alias
* Security: Check path for forbidden access after unescaping

**2.3.0** (January 16, 2012)

* Added special Sass importer that automatically tracks any `@import`ed files.

**2.2.0** (January 10, 2012)

* Added `sprockets` command line utility.
* Added rake/sprocketstask.
* Added json manifest log of compiled assets.
* Added `stub` directive that allows you to exclude files from the bundle.
* Added per environment external encoding (Environment#default_external_encoding). Defaults to UTF-8. Fixes issues where LANG is not set correctly and Rubys default external is set to ASCII.

**2.1.2** (November 20, 2011)

* Disabled If-Modified-Since server checks. Fixes some browser caching issues when serving the asset body only. If-None-Match caching is sufficient.

**2.1.1** (November 18, 2011)

* Fix windows absolute path check bug.

**2.1.0** (November 11, 2011)

* Directive comment lines are now turned into empty lines instead of removed. This way line numbers in
  CoffeeScript syntax errors are correct.
* Performance and caching bug fixes.

**2.0.3** (October 17, 2011)

* Detect format extensions from right to left.
* Make JST namespace configurable.

**2.0.2** (October 4, 2011)

* Fixed loading stale cache from bundler gems.

**2.0.1** (September 30, 2011)

* Fixed bug with fingerprinting file names with multiple dots.
* Decode URIs as default internal.
* Fix symlinked asset directories.

**2.0.0** (August 29, 2011)

* Initial public release.

## License

Copyright &copy; 2014 Sam Stephenson <<sstephenson@gmail.com>>

Copyright &copy; 2014 Joshua Peek <<josh@joshpeek.com>>

Sprockets is distributed under an MIT-style license. See LICENSE for
details.