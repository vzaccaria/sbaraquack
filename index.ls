
_               = require('underscore')
_.str           = require('underscore.string');
moment          = require 'moment'
fs              = require 'fs'
color           = require('ansi-color').set
{ spawn, kill } = require('child_process')
__q             = require('q')
sh              = require('shelljs')
os              = require('os')
shelljs         = sh
winston         = require('winston')
debug = require('debug')('glp:sbarackquack')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');



_module = ->

    task-set = {}

    fill-w-example-set = ->
        padd-task \c, [ \a \g \b \d ] 
        add-task \d, [ \a \b ]
        padd-task \b, []
        padd-task \g, [ \b \g ]
        padd-task \a, [ \b ]

    print-set = ->
        console.log JSON.stringify(task-set, 0, 4)


    _add-task = (t, deps, cb, options) ->
        task-set[t] = { deps: deps, cb: cb }
        options ?= {}
        if options.parallel? and options.parallel
            task-set[t].parallel-deps = true
        else 
            task-set[t].parallel-deps = false

    add-task = (t, deps, cb) ->
        _add-task t, deps, cb, { }

    padd-task = (t, deps, cb) ->
        _add-task t, deps, cb, { +parallel }

        
    schedule = []

    init-schedule = ->
        schedule = []

    schedule-task = (t, deps, cb) ->
        schedule.push(-> add-task(t, deps, cb))

    commit-schedule = ->
        unfold-deps()

        # commit scheduled changes 
        for s in schedule 
            s()

    start-gulp = (options) ->
        commit-schedule()
        if options?.dry? and options.dry
            for task,props in task-set
                debug("Would have started #task with deps: #{props.deps}")
        else 
            for task,props in task-set
                gulp.task task, props.deps, props.cb
 

    unfold-deps = ->
        for task,props of task-set
            task-deps = props.deps 
            if props.parallel-deps == false
                if task-deps.length > 1
                    for n from (task-deps.length - 1) to 0 by -1
                        prec-tasks = _.first(task-deps, n)
                        prec-task = _.last(prec-tasks)
                        new-task = task-deps[n]

                        if not task-set[new-task]? 
                            throw "Sorry, '#new-task' not defined"

                        if prec-task?
                            schedule-task("#{new-task}-#{task}", ["#{prec-task}-#{task}"], task-set[new-task].cb)
                        else 
                            schedule-task("#{new-task}-#{task}", [], task-set[new-task].cb )

    test = ->
        fill-w-example-set()
        commit-schedule()
        print-set()

    iface = { 
        task: add-task
        ptask: padd-task
        start-gulp: start-gulp

        # Testing
        test: test
        print-set: print-set
        fill-w-example-set: fill-w-example-set
    }
  
    return iface

# _module().test()
 
module.exports = _module()

