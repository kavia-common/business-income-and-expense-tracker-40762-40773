const http=require('http'); const server=require('../functions/http/index'); let srv,port;
beforeAll(done=>{ srv=server.listen(0,()=>{ port=srv.address().port; done(); }); });
afterAll(done=>{ srv.close(done); });
test('health',async()=>{ const res=await new Promise((res,rej)=>{ http.get('http://127.0.0.1:'+port+'/health',r=>{ let d=''; r.on('data',c=>d+=c); r.on('end',()=>res({status:r.statusCode,body:d})); }).on('error',rej); }); expect(res.status).toBe(200); expect(JSON.parse(res.body).ok).toBeTruthy(); },10000);
