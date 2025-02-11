08:15:23 PM [  script:ds-supabase] is key   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttdWRydWtpeGFnaWZ5bmpkaGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkxMjk1NTksImV4cCI6MjA1NDcwNTU1OX0.-6I-3WNt4QYu25tHE-65j7kQFbudiKHkvTFbYIXScJg
08:15:23 PM [  script:ds-supabase] is url   https://kmudrukixagifynjdhey.supabase.co
08:15:23 PM [  script:ds-supabase] Called SupabaseClient:from
08:15:23 PM [  script:ds-supabase] QueryBuilder:upsert
08:15:23 PM [  script:ds-supabase] QueryBuilder:single
08:15:23 PM [  script:ds-supabase] QueryBuilder:await
08:15:23 PM [  script:ds-supabase] Formed URL: https://kmudrukixagifynjdhey.supabase.co/rest/v1/players?select=*&upsert=true&on_conflict=name
08:15:23 PM [  script:ds-supabase] URL: https://kmudrukixagifynjdhey.supabase.co/rest/v1/players?select=*&upsert=true&on_conflict=name
08:15:23 PM [  script:ds-supabase] Method: POST
08:15:23 PM [  script:ds-supabase] Payload: {"name":"TestPlayer"}
08:15:23 PM [  script:ds-supabase] Headers: { ["Prefer"] = resolution=merge-duplicates,["apikey"] = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttdWRydWtpeGFnaWZ5bmpkaGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkxMjk1NTksImV4cCI6MjA1NDcwNTU1OX0.-6I-3WNt4QYu25tHE-65j7kQFbudiKHkvTFbYIXScJg,["Authorization"] = Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttdWRydWtpeGFnaWZ5bmpkaGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkxMjk1NTksImV4cCI6MjA1NDcwNTU1OX0.-6I-3WNt4QYu25tHE-65j7kQFbudiKHkvTFbYIXScJg,["Content-Type"] = application/json,} 
08:15:23 PM [  script:ds-supabase] 
08:15:23 PM [  script:ds-supabase] 
08:15:23 PM [           resources] Started resource ds-test
08:15:24 PM [  script:ds-supabase] Status code is 400
08:15:24 PM [  script:ds-supabase] Error data: HTTP 400: {"code":"PGRST100","details":"unexpected \"t\" expecting \"not\" or operator (eq, gt, ...)","hint":null,"message":"\"failed to parse filter (true)\" (line 1, column 1)"}
08:15:24 PM [  script:ds-supabase] SCRIPT ERROR: @ds-supabase/server/main.lua:443: attempt to index a nil value (local 'decoded')
08:15:24 PM [  script:ds-supabase] > userCallback (@ds-supabase/server/main.lua:443)