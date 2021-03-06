%% @copyright Geoff Cant
%% @author Geoff Cant <nem@erlang.geek.nz>
%% @version {@vsn}, {@date} {@time}
%% @doc ECTR Report execution library
%% @end
-module(ectr_report).

-include("ectr_log.hrl").

-type report() :: ectr_fold_report:report() |
                  ectr_each_report:report().

-export_type([report/0]).

-export([start_link/4]).

%% proc_lib callback
-export([report_init/4]).

-spec start_link(report(), erlang:timestamp(), ets:tab(), ectr_gc:gc()) ->
                        {ok, pid()} | {error, any()}.
start_link(Report, TS, Tab, GC) ->
    proc_lib:start_link(?MODULE, report_init, [Report, TS, Tab, GC]).

report_init(Report, TS, Tab, GC) ->
    proc_lib:init_ack({ok, self()}),
    try
        run_report(Report, TS, Tab, GC),
        ectr_gc:sweep(Tab, GC)
    catch
        C:E ->
            ?ERR("at=report_failed class=~p error=~p stack=~1000p",
                 [C, E, erlang:get_stacktrace()])
    end,
    ok.

run_report({ectr_fold_report, _} = Fold, TS, Tab, GC) ->
    ectr_fold_report:run(Fold, TS, Tab, GC);
run_report({ectr_each_report, _} = Each, TS, Tab, GC) ->
    ectr_each_report:run(Each, TS, Tab, GC).
