-- =========================================================
-- SEMEIA — schema do Supabase
-- Cole este arquivo inteiro no SQL Editor do seu projeto
-- Supabase (menu lateral "SQL Editor" → "New query") e
-- clique em "Run".
-- =========================================================

-- 1) Tabela de perfis (um por usuário, criada automaticamente no cadastro)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text,
  points int default 0,
  created_at timestamp with time zone default now()
);

-- 2) Tabela de plantas cadastradas por cada usuário
create table if not exists public.plants (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  planted_date date default current_date,
  stage text default 'Semente na terra',
  created_at timestamp with time zone default now()
);

-- 3) Segurança: cada usuário só enxerga e edita os próprios dados
alter table public.profiles enable row level security;
alter table public.plants enable row level security;

create policy "profiles: usuário vê o próprio" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles: usuário edita o próprio" on public.profiles
  for update using (auth.uid() = id);
create policy "profiles: usuário cria o próprio" on public.profiles
  for insert with check (auth.uid() = id);

create policy "plants: usuário vê as próprias" on public.plants
  for select using (auth.uid() = user_id);
create policy "plants: usuário cria as próprias" on public.plants
  for insert with check (auth.uid() = user_id);
create policy "plants: usuário atualiza as próprias" on public.plants
  for update using (auth.uid() = user_id);
create policy "plants: usuário apaga as próprias" on public.plants
  for delete using (auth.uid() = user_id);

-- 4) Gatilho: cria o perfil automaticamente assim que alguém se cadastra
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', new.email));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
