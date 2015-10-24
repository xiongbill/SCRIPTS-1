--###########################################
--## Final Blocking Session in 11.2 - Troubleshooting Database Contention With V$Wait_Chains [ID 1428210.1]
--###########################################

set pages 1000
set lines 190
set heading off
column w_proc format a50 tru
column instance format a20 tru
column inst format a28 tru
column wait_event format a50 tru
column p1 format a16 tru
column p2 format a16 tru
column p3 format a15 tru
column Seconds format a50 tru
column sincelw format a50 tru
column blocker_proc format a50 tru
column fblocker_proc format a50 tru
column waiters format a50 tru
column chain_signature format a100 wra
column blocker_chain format a50 wra
column blocker_sid format a50 tru
column waiter_sid format a25 tru
SELECT    *
   FROM
      (SELECT 'Current Process: '||osid ||' ('||wc.sid||')' W_PROC,
            'SID '||i.instance_name INSTANCE  ,
            'INST #: '||instance INST         ,
            'Blocking Process: '||DECODE(blocker_osid,NULL,'<none>',blocker_osid)|| ' from Instance '||blocker_instance
            BLOCKER_PROC                              ,
            'Number of waiters: '||num_waiters waiters,
            'Final Blocking Process: '||DECODE(p.spid,NULL,'<none>', p.spid)||' from Instance '||
            s.final_blocking_instance FBLOCKER_PROC                         ,
            'Program: '||p.program image                                    ,
            'Wait Event: ' ||wait_event_text wait_event                     ,
            'P1: '||wc.p1 p1                                                ,
            'P2: '||wc.p2 p2                                                ,
            'P3: '||wc.p3 p3                                                ,
            'Seconds in Wait: '||in_wait_secs Seconds                       ,
            'Seconds Since Last Wait: '||time_since_last_wait_secs sincelw  ,
            'Wait Chain: '||chain_id ||': '||chain_signature chain_signature,
            'Blocking Wait Chain: '||DECODE(blocker_chain_id,NULL, '<none>',blocker_chain_id) blocker_chain
	    --,'Blocking session id: '||bs.sid blocker_sid,
	    --'Waiting session id: '||s.sid waiter_sid
         FROM v$wait_chains wc,
            gv$session s      ,
            gv$session bs     ,
            gv$instance i     ,
            gv$process p
         WHERE wc.instance               = i.instance_number (+)
            AND (wc.instance             = s.inst_id (+)
            AND wc.sid                   = s.sid (+)
            AND wc.sess_serial#          = s.serial# (+))
            AND (s.inst_id               = bs.inst_id (+)
            AND s.final_blocking_session = bs.sid (+))
            AND (bs.inst_id              = p.inst_id (+)
            AND bs.paddr                 = p.addr (+))
            AND ( num_waiters            > 0
            OR ( blocker_osid           IS NOT NULL
            AND in_wait_secs             > 10 ) )
         ORDER BY chain_id,
            num_waiters DESC
      )
   WHERE ROWNUM < 101;

set head on;
