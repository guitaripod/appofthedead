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
  // Get Apple user ID from header
  const appleUserId = request.headers.get('X-Apple-User-Id');
  if (!appleUserId) {
    return new Response(
      JSON.stringify({ error: 'Missing X-Apple-User-Id header' }), 
      { 
        status: 401, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
  
  try {
    // Get sync data from request
    const syncData: SyncData = await request.json();
    
    // Perform sync
    const syncService = new SyncService(env);
    const syncedData = await syncService.syncData(appleUserId, syncData);
    
    return new Response(
      JSON.stringify(syncedData), 
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Sync error:', error);
    return new Response(
      JSON.stringify({ error: 'Sync failed', details: error instanceof Error ? error.message : 'Unknown error' }), 
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
}