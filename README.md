# Rollup copy

Rollup plugin to copy node modules or any files to target directory. Plugin looks for files in the source directory and just copies them to the target directory. Also, the plugin checks the file size and date and, if it is the same, doesn't copy files. Support standard JS regular expressions to select files by their name.

Example configuration:

```js
import copy from '@voidvolker/rollup-copy'

export default {
    plugins: [
        copy({
            modules: [
                // Common js modules
                'mermaid/dist/mermaid.min.js',
                'svg-pan-zoom/dist/svg-pan-zoom.min.js',
                // First item in array - directory, all other items - files in that directory
                // Copy two files from module w2ui
                ['w2ui', 'w2ui-2.0.es6.min.js', 'w2ui-2.0.css'],
                // Copy fonts by regexp
                ['@fortawesome/fontawesome-free/webfonts', /fa-\w+-\d+\.woff2/], // -> fa-brands-400.woff2, fa-regular-400.woff2, fa-solid-900.woff2
                // Copy styles by regexp
                ['@fortawesome/fontawesome-free/css', /^(all|brands|fontawesome|regular|solid)\.min\.css$/] // -> all.min.css, brands.min.css, fontawesome.min.css, regular.min.css, solid.min.css
            ],
            // Optional
            source: 'node_modules',
            target: 'dist/vendor',
            silent: false,
            debug: false
        })
    ]
}
```

## Configuration options

| Options | Type | Default | Description |
|---|---|---|---|
| `modules` | `Array` | `[]` | Array of `string` or `Array<string\|RegExp>`: path to one source file or path to directory and list of files |
| `source` | `string` | `'node_modules'` | Files source directory |
| `target` | `string` | `'dist/vendor'` | Files target directory |
| `silent` | `boolean` | `false` | Silent mode - do not type anything to console |
| `debug` | `boolean` | `false` | Debug mode - usefull for debugging |

`modules` option value examples:
```js
[
    'path/to/one/file',
    ['path/to/directory 1', 'file 1', 'file 2', 'file n'],
    ['path/to/directory 2', 'file 1', 'file n', /file regex 1/, /file regex n/]
]
```

## Development

- `npm run make` — transpile module to js
- `npm run watch` — watch for files changes and transpile module in realtime
