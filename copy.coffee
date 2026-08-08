import { statSync, existsSync, mkdirSync, copyFileSync, rmSync, utimesSync, readdirSync } from 'node:fs'
import { resolve, parse, join, sep } from 'node:path'
import { execSync } from 'child_process'

class RollupCopy

    @defaultTarget: 'dist/vendor'
    @defaultSource: 'node_modules'

    constructor: (opt) ->
        this.opt = opt
        this.buildStart = RollupCopy.buildStart.bind this # I know this isn't a good solution, but rollup calls plugin via call with context - what else solution can be here?

    @processRegExp: (modules, sourceDir, debug) ->
        processed = []
        for module in modules
            if Array.isArray module
                if module.length < 2
                    throw new Error 'Expected array with 2 and more items:' + module.join()
                    continue

                moduleRoot = module.shift()
                sourceRoot = join sourceDir, moduleRoot

                if statSync(sourceRoot).isDirectory()
                    if debug then console.log '[Copy DEBUG]     founded module directory:', sourceRoot

                    while module.length > 0
                        subModule = module.shift()
                        if subModule instanceof RegExp
                            if debug then console.log '[Copy DEBUG]         founded regex:', subModule
                            sourceFiles = readdirSync sourceRoot
                            for file in sourceFiles
                                if subModule.test file
                                    processed.push join moduleRoot, file
                                    if debug then console.log '[Copy DEBUG]             matching file:', file
                        else
                            processed.push join moduleRoot, subModule
                else
                    throw new Error 'Not a directory. Expected directory:' + sourceRoot
            else
                processed.push module
        processed

    @buildStart: (rollupOptions) ->
        silent = @opt.silent
        debug = @opt.debug
        source = @opt.source or @constructor.defaultSource
        target = @opt.target or @constructor.defaultTarget
        sourceDir = resolve './', 'node_modules'
        targetDir = resolve './', target

        if debug
            console.log '[Copy DEBUG] === DEBUG MODE DETECTED ==='
            console.log '[Copy DEBUG] plugin options:', @opt
            console.log '[Copy DEBUG] source directory:', sourceDir
            console.log '[Copy DEBUG] target directory:', targetDir

        # Checking and creating target
        if existsSync targetDir
            if not statSync(targetDir).isDirectory()
                throw new Error 'Not a directory. Expected directory: ' + targetDir
        else
            if not silent
                console.log '[Copy] directory creating:', targetDir
            mkdirSync targetDir, recursive: true

        if not Array.isArray @opt.modules
            # Nothing to do
            return

        if debug then console.log '[Copy DEBUG] modules regex processing started'

        modules = RollupCopy.processRegExp @opt.modules, sourceDir, debug

        if debug then console.log '[Copy DEBUG] processed modules:', modules

        # Process modules
        for module in modules
            # Process soruce and target paths
            modulePath = join sourceDir, module
            parsedModule = parse module
            moduleFile = parsedModule.base
            moduleDir = parsedModule.dir
            targetModuleDir = resolve targetDir, moduleDir
            targetPath = join targetModuleDir, moduleFile
            relatvieTarget = join target, moduleDir, moduleFile

            # Check target directory and create if it's not yet exists
            if not existsSync targetModuleDir
                if not silent then console.log '[Copy] directory creating:', join target, moduleDir
                mkdirSync targetModuleDir, recursive: true

            # Check if source file exists and it is a file
            if not (existsSync(modulePath) and statSync(modulePath).isFile())
                throw new Error 'File not found: ' + modulePath

            sourceStat = statSync modulePath

            if existsSync targetPath # Update file
                targetStat = statSync targetPath
                # Drop milliseconds
                sourceTS = Math.floor sourceStat.mtime.getTime() / 1000
                targetTS = Math.floor targetStat.mtime.getTime() / 1000

                if debug
                    console.log '[Copy DEBUG] module: [', module, ']'
                    console.log '[Copy DEBUG] source file date and size:', sourceStat.mtime, sourceStat.size
                    console.log '[Copy DEBUG] target file date and size:', targetStat.mtime, targetStat.size
                    console.log '[Copy DEBUG]'

                # Check for file changes
                if (sourceTS isnt targetTS) or (sourceStat.size isnt targetStat.size)
                    if not silent then console.log  '[Copy] file updating:', module, ' → ', relatvieTarget
                    # Remove and copy file as-is
                    rmSync targetPath
                    copyFileSync modulePath, targetPath
                    # Sync files times
                    utimesSync targetPath, sourceStat.atime, sourceStat.mtime

            else # Copy file
                if not silent then console.log '[Copy] file copying:', module, ' → ', relatvieTarget
                # Copy file
                copyFileSync modulePath, targetPath
                # Sync files times
                utimesSync targetPath, sourceStat.atime, sourceStat.mtime

    @export: (options) -> new RollupCopy options

export default RollupCopy.export
