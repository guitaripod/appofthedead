import { Env, SyncData } from './types';
import { AppleAuth } from './auth';
import { SyncService } from './sync';

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
    
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }
    
    try {
      // Route handling
      if (url.pathname === '/sync' && request.method === 'POST') {
        return await handleSync(request, env, corsHeaders);
      }
      
      if (url.pathname === '/health' && request.method === 'GET') {
        return new Response(JSON.stringify({ status: 'ok' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
      
      return new Response('Not Found', { status: 404, headers: corsHeaders });
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(
        JSON.stringify({ error: 'Internal Server Error' }), 
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }
  },
};

async function handleSync(request: Request, env: Env, corsHeaders: Record<string, string>): Promise<Response> {
  // Check authorization header
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }), 
      { 
        status: 401, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
  
  const token = authHeader.substring(7);
  
  // Verify Apple identity token
  const appleAuth = new AppleAuth(env);
  const tokenPayload = await appleAuth.verifyIdentityToken(token);
  
  if (!tokenPayload) {
    return new Response(
      JSON.stringify({ error: 'Invalid token' }), 
      { 
        status: 401, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
  
  // Get sync data from request
  const syncData: SyncData = await request.json();
  
  // Perform sync
  const syncService = new SyncService(env);
  const userInfo = appleAuth.extractUserInfo(tokenPayload);
  const syncedData = await syncService.syncData(userInfo.appleId, syncData);
  
  return new Response(
    JSON.stringify(syncedData), 
    { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}