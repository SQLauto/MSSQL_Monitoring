select vf.*, sys.filename, sys.name  
from ::fn_virtualfilestats(-1, -1) vf, master..sysaltfiles sys with (nolock) 
where vf.dbid = sys.dbid and vf.fileid = sys.fileid and vf.dbid > 7 order by vf.IoStallMs desc 