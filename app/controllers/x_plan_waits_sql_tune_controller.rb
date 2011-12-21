class XPlanWaitsSqlTuneController < ApplicationController
    
    def index
    end
    
    def generate_and_show
        # Data Format of params: "sql_ids_data"=>{"sql_ids"=>"10\r\n20\r\n30\r\n40"}
        sql_ids = params["sql_ids_data"]["sql_ids"].split("\s")
        
        @script = ""
        @script << "Rem XPlanWaitsSQLTune.sql\n"
        @script << "Rem\n"
        @script << "Rem    NAME\n"
        @script << "Rem      XPlanWaitsSQLTune.sql\n"
        @script << "Rem\n"
        @script << "Rem    Description\n"
        @script << "Rem      SQL*Plus script to pull out the execution plan, wait\n"
        @script << "Rem      events and SQL Tuning Advisor information for a set of\n"
        @script << "Rem      SQL_IDs.\n"
        @script << "Rem\n"
        @script << "Rem        sqlplus system/password @XPlanWaitsSQLTune.sql\n"
        @script << "Rem\n"
        @script << "Rem    NOTES\n"
        @script << "Rem      Execute the script as SYS, SYSTEM or as a user\n"
        @script << "Rem      with the ADVISOR system privilege.\n"
        @script << "Rem\n\n"
            
        @script << "spool XPlanWaitsSQLTune.out\n\n"

        @script << "set echo off\n"
        @script << "set feedback off\n"
        @script << "set linesize 150\n"
        @script << "set long 2000000000\n"
        @script << "set longchunk 1000\n"
        @script << "set pagesize 50000\n"
        @script << "set serveroutput on size unlimited\n"
        @script << "set term off\n\n"

        @script << "variable task varchar2(64);\n\n"

        for sql_id in sql_ids
            if sql_id =~ /([a-z0-9]{13})/
                @script << "prompt ********************\n"
                @script << "prompt SQL_ID=#{$1}\n"
                @script << "prompt ********************\n\n"

                @script << "prompt\n"
                @script << "prompt Execution Plan (V$SQL)\n"
                @script << "prompt **********************\n"
                @script << "prompt\n"
                @script << "select * from table(dbms_xplan.display_cursor('#{$1}',null,'ALL'));\n\n"

                @script << "prompt\n"
                @script << "prompt Wait Events (V$ACTIVE_SESSION_HISTORY)\n"
                @script << "prompt **************************************\n"
                @script << "prompt\n"
                @script << "select event, sum(time_waited) time_waited\n"
                @script << "from v$active_session_history\n"
                @script << "where sql_id = '#{$1}'\n"
                @script << "group by event\n"
                @script << "order by time_waited desc;\n\n"

                @script << "prompt\n"
                @script << "prompt Execution Plan (DBA_HIST_SQLTEXT)\n"
                @script << "prompt *********************************\n"
                @script << "prompt\n"
                @script << "select * from table(dbms_xplan.display_awr('#{$1}',null,null,'ALL'));\n\n"

                @script << "prompt\n"
                @script << "prompt Wait Events (DBA_HIST_ACTIVE_SESS_HISTORY)\n"
                @script << "prompt ******************************************\n"
                @script << "prompt\n"
                @script << "select event, sum(time_waited) time_waited\n"
                @script << "from dba_hist_active_sess_history\n"
                @script << "where sql_id = '#{$1}'\n"
                @script << "group by event\n"
                @script << "order by time_waited desc;\n\n"
                
                @script << "prompt\n"
                @script << "prompt SQL Tuning Advisor\n"
                @script << "prompt ******************\n"
                @script << "prompt\n"
                @script << "execute :task := dbms_sqltune.create_tuning_task(sql_id => '#{$1}');\n"
                @script << "execute dbms_sqltune.execute_tuning_task(:task);\n"
                @script << "select dbms_sqltune.report_tuning_task(:task,'TEXT','ALL','ALL') from dual;\n"
                @script << "select dbms_sqltune.script_tuning_task(:task,'ALL') from dual;\n"
                @script << "execute dbms_sqltune.drop_tuning_task(:task);\n\n"

                @script << "prompt\n"
                @script << "prompt\n"
                @script << "prompt\n\n\n"
            end
        end
        @script << "spool off\n"
        @script << "quit\n"
        
        @navigate_back = {:link => "x_plan_waits_sql_tune", :name => "XPlan, Waits & SQL Tune"}
    end
        
end
