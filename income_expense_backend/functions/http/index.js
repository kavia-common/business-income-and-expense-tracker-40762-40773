// Minimal HTTP function for smoke testing
const http = require('http');
const server = http.createServer((req,res)=>{
  if(req.url==='/health') return res.writeHead(200,{'Content-Type':'application/json'}) && res.end(JSON.stringify({ok:true}));
  res.writeHead(404); res.end('not found');
});
if(require.main===module){ const PORT=process.env.PORT||54321; server.listen(PORT,()=>console.log('listening',PORT)); }
module.exports=server;
