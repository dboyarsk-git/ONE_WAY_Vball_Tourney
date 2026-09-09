ONE WAY — CAPTAIN EMAIL SETUP

The website is already coded to call the function automatically after a successful registration.

WHY AN EDGE FUNCTION
Your Resend API key is private and must never be placed in index.html.
The Edge Function sends the email server-side and checks the exact registration confirmation token before sending.

SETUP
1. Create a Resend account and create an API key.
2. For real emails to tournament captains, verify a sending domain in Resend.
   Once you own onewaygrass.com, a good sender is:
   ONE WAY Grass 4s <registration@onewaygrass.com>

3. Supabase Dashboard -> Edge Functions.
4. Create a function named EXACTLY:
   send-captain-registration-email

5. Paste the included:
   supabase/functions/send-captain-registration-email/index.ts

6. Turn JWT verification OFF for this function.
   The function performs its own registration-token verification and limits the automatic email to one successful send per registration.

7. Supabase -> Edge Functions -> Secrets. Add:
   RESEND_API_KEY = your Resend API key
   CAPTAIN_FROM_EMAIL = ONE WAY Grass 4s <registration@your-verified-domain.com>
   SITE_URL = https://dboyarsk-git.github.io/ONE_WAY_Vball_Tourney/

8. Deploy the function.

WHEN YOU CHANGE TO A CUSTOM DOMAIN
Change SITE_URL to:
https://onewaygrass.com/

No website code change is required just for that URL update.

WHAT THE CAPTAIN RECEIVES
- Thank-you message
- Team name
- Submitted four-player roster
- Current reserved/waitlist status
- One team confirmation link
- Instructions to share that link with every teammate

SAFETY
- RESEND_API_KEY stays only in Supabase Secrets.
- The browser never receives the email API key.
- The Edge Function verifies the registration ID + confirmation token.
- One automatic email is claimed per registration.
- Resend receives an idempotency key to protect against duplicate retries.
