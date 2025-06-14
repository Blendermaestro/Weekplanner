# Weekly Shift Planner - Web App Setup

## 🚀 Supabase Setup

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note down your project URL and anon key

### 2. Run SQL Schema
1. Go to Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `supabase_schema.sql`
3. Run the SQL to create all tables and functions

### 3. Configure Authentication
1. Go to Authentication → Settings
2. Enable email authentication
3. Configure email templates if needed
4. Set up redirect URLs for your domain

### 4. Update Flutter App
1. Open `lib/main.dart`
2. Replace `YOUR_SUPABASE_URL` with your project URL
3. Replace `YOUR_SUPABASE_ANON_KEY` with your anon key

## 🌐 GitHub Pages Deployment

### 1. Build for Web
```bash
flutter build web --release
```

### 2. Deploy to GitHub Pages
1. Create a new repository on GitHub
2. Push your code to the repository
3. Copy the `build/web` contents to a `docs` folder or `gh-pages` branch
4. Enable GitHub Pages in repository settings
5. Set source to `docs` folder or `gh-pages` branch

### 3. Configure Domain (Optional)
1. Add your custom domain in GitHub Pages settings
2. Update Supabase redirect URLs to match your domain

## 📱 Mobile Web Support

The app is fully responsive and works on:
- ✅ Desktop browsers (Chrome, Firefox, Safari, Edge)
- ✅ Mobile browsers (iOS Safari, Android Chrome)
- ✅ Tablet browsers
- ✅ PWA (Progressive Web App) capable

## 🔐 Security Features

- **Row Level Security (RLS)**: Each user can only access their own data
- **Authentication**: Secure email/password authentication via Supabase
- **Data Isolation**: Complete separation between user accounts
- **Secure API**: All database operations go through Supabase's secure API

## 📊 Database Schema

### Tables Created:
- `user_profiles` - User profile information
- `master_classes` - Master class configurations (A, B, C, D)
- `housing_units` - Housing unit definitions
- `profession_capacities` - Profession capacity settings
- `workers` - Worker assignments and information

### Default Data:
Each new user gets:
- 4 master classes (A, B, C, D)
- 7 housing units (Etelärakka A/B, Levijärvi A/B)
- 11 profession capacities (Työnjohtaja, Varu 1-4, etc.)

## 🛠️ Development

### Local Development
```bash
flutter run -d chrome
```

### Build for Production
```bash
flutter build web --release
```

## 📝 Environment Variables

Create a `.env` file (not committed to git):
```
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_anon_key_here
```

## 🔄 Data Sync

- **Real-time**: Changes sync immediately to Supabase
- **Offline**: Basic offline support via browser caching
- **Multi-device**: Access your data from any device
- **Backup**: All data stored securely in Supabase cloud

## 🎯 Features

- ✅ User authentication (signup/login)
- ✅ Personal shift planning data
- ✅ PDF export functionality
- ✅ Responsive design for all devices
- ✅ Real-time data synchronization
- ✅ Secure multi-user support
- ✅ Finnish localization 