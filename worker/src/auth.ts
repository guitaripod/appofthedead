import { Env, AppleTokenPayload } from './types';

export class AppleAuth {
  private env: Env;

  constructor(env: Env) {
    this.env = env;
  }

  async verifyIdentityToken(identityToken: string): Promise<AppleTokenPayload | null> {
    try {
      // Decode the identity token header to get the key ID
      const [headerBase64] = identityToken.split('.');
      const headerJson = atob(headerBase64);
      const header = JSON.parse(headerJson);
      const keyId = header.kid;

      // Fetch Apple's public keys
      const keysResponse = await fetch('https://appleid.apple.com/auth/keys');
      const keys = await keysResponse.json();
      
      // Find the matching key
      const publicKey = keys.keys.find((key: any) => key.kid === keyId);
      if (!publicKey) {
        console.error('Public key not found');
        return null;
      }

      // Import the public key
      const jwk = {
        kty: publicKey.kty,
        n: publicKey.n,
        e: publicKey.e,
        alg: publicKey.alg,
        use: publicKey.use,
      };

      const key = await crypto.subtle.importKey(
        'jwk',
        jwk,
        {
          name: 'RSASSA-PKCS1-v1_5',
          hash: 'SHA-256',
        },
        false,
        ['verify']
      );

      // Verify the token
      const [, payloadBase64, signatureBase64] = identityToken.split('.');
      const signatureBuffer = this.base64UrlToBuffer(signatureBase64);
      const dataToVerify = new TextEncoder().encode(`${headerBase64}.${payloadBase64}`);

      const isValid = await crypto.subtle.verify(
        'RSASSA-PKCS1-v1_5',
        key,
        signatureBuffer,
        dataToVerify
      );

      if (!isValid) {
        console.error('Token signature invalid');
        return null;
      }

      // Decode and validate the payload
      const payloadJson = atob(payloadBase64.replace(/-/g, '+').replace(/_/g, '/'));
      const payload: AppleTokenPayload = JSON.parse(payloadJson);

      // Validate token claims
      const now = Math.floor(Date.now() / 1000);
      
      if (payload.iss !== 'https://appleid.apple.com') {
        console.error('Invalid issuer');
        return null;
      }

      if (payload.aud !== this.env.APPLE_CLIENT_ID) {
        console.error('Invalid audience');
        return null;
      }

      if (payload.exp < now) {
        console.error('Token expired');
        return null;
      }

      return payload;
    } catch (error) {
      console.error('Error verifying Apple identity token:', error);
      return null;
    }
  }

  private base64UrlToBuffer(base64url: string): ArrayBuffer {
    const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
    const padding = '='.repeat((4 - (base64.length % 4)) % 4);
    const base64WithPadding = base64 + padding;
    const binaryString = atob(base64WithPadding);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
  }

  extractUserInfo(payload: AppleTokenPayload) {
    return {
      appleId: payload.sub,
      email: payload.email,
      emailVerified: payload.email_verified === 'true',
    };
  }
}