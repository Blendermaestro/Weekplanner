-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Create custom types
CREATE TYPE shift_type AS ENUM ('day', 'night', 'off');

-- Users table (extends Supabase auth.users)
CREATE TABLE public.user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Master Classes table
CREATE TABLE public.master_classes (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  display_name TEXT NOT NULL,
  shift_type shift_type NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.master_classes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own master classes" ON public.master_classes
  FOR ALL USING (auth.uid() = user_id);

-- Housing Units table
CREATE TABLE public.housing_units (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  display_name TEXT NOT NULL,
  shift_type shift_type NOT NULL,
  max_capacity INTEGER NOT NULL DEFAULT 4,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.housing_units ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own housing units" ON public.housing_units
  FOR ALL USING (auth.uid() = user_id);

-- Profession Capacities table
CREATE TABLE public.profession_capacities (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  profession TEXT NOT NULL,
  max_day_capacity INTEGER NOT NULL DEFAULT 2,
  max_night_capacity INTEGER NOT NULL DEFAULT 2,
  available_at_night BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, profession)
);

ALTER TABLE public.profession_capacities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own profession capacities" ON public.profession_capacities
  FOR ALL USING (auth.uid() = user_id);

-- Workers table
CREATE TABLE public.workers (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  name TEXT NOT NULL,
  profession TEXT NOT NULL,
  master_class_id TEXT REFERENCES public.master_classes(id),
  housing_id TEXT REFERENCES public.housing_units(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own workers" ON public.workers
  FOR ALL USING (auth.uid() = user_id);

-- Function to handle user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  
  -- Insert default master classes
  INSERT INTO public.master_classes (id, user_id, display_name, shift_type) VALUES
    ('A', NEW.id, 'Master Class A', 'day'),
    ('B', NEW.id, 'Master Class B', 'night'),
    ('C', NEW.id, 'Master Class C', 'day'),
    ('D', NEW.id, 'Master Class D', 'day');
  
  -- Insert default housing units
  INSERT INTO public.housing_units (id, user_id, display_name, shift_type, max_capacity) VALUES
    ('eta-a-day', NEW.id, 'Etelärakka A', 'day', 4),
    ('eta-a-night', NEW.id, 'Etelärakka A', 'night', 4),
    ('eta-b-day', NEW.id, 'Etelärakka B', 'day', 4),
    ('eta-b-night', NEW.id, 'Etelärakka B', 'night', 4),
    ('levi-a-day', NEW.id, 'Levijärvi A', 'day', 4),
    ('levi-b-night', NEW.id, 'Levijärvi B', 'night', 4),
    ('levi-a-off', NEW.id, 'Levijärvi A', 'off', 4);
  
  -- Insert default profession capacities
  INSERT INTO public.profession_capacities (user_id, profession, max_day_capacity, max_night_capacity, available_at_night) VALUES
    (NEW.id, 'Työnjohtaja', 1, 1, true),
    (NEW.id, 'Varu 1', 2, 2, true),
    (NEW.id, 'Varu 2', 2, 2, true),
    (NEW.id, 'Varu 3', 2, 2, true),
    (NEW.id, 'Varu 4', 2, 2, true),
    (NEW.id, 'Pasta 1', 2, 2, true),
    (NEW.id, 'Pasta 2', 2, 2, true),
    (NEW.id, 'Huoltomies', -1, 0, false),
    (NEW.id, 'Tarvikeauto', 1, 1, true),
    (NEW.id, 'ICT', 2, 0, false),
    (NEW.id, 'Pora', 1, 0, false);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to all tables
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.master_classes
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.housing_units
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.profession_capacities
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.workers
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at(); 