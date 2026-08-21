# M4 Hub v2 — Shared Family Setup

M4 Hub works locally without any cloud setup. To make tasks, shopping, messages and schedules appear on all four phones, connect it to a free Supabase project.

## One-time setup

1. Create a free project at Supabase.
2. In Supabase, open **SQL Editor**.
3. Open `supabase-setup.sql` from this package, paste all of it into the SQL Editor and click **Run**.
4. In Supabase, open **Project Settings → API**.
5. Copy:
   - Project URL
   - anon / public key
6. Open M4 Hub → **More → Shared family sync** and paste both values.
7. Each family member creates an account with their own email/password.

## Creating the M4 household

Only one person does this:
1. Select their name.
2. Sign in.
3. Tap **Create M4 household**.
4. The app shows an invite code.

The other three:
1. Use the same Supabase URL and anon key.
2. Create/sign into their own account.
3. Select their own name.
4. Enter the invite code and tap **Join household**.

After that, tasks, shopping, board messages and schedule entries synchronize between the phones.

## Dinner rota

The rota is automatic every week:
- Mariana: 1 dinner
- Marcia: 2 dinners
- Morad: 2 dinners
- Mustapha: 2 dinners

The days rotate each week so the same person is not permanently stuck with the same weekday.
