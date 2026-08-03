import sqlite3
from datetime import datetime
from sqlalchemy import text
from app.db.database import engine

def migrate():
    sqlite_conn = sqlite3.connect('d:/jaldrishti/jaldrishti-backend/jaldrishti.db')
    sqlite_conn.row_factory = sqlite3.Row
    sqlite_cur = sqlite_conn.cursor()

    print("Starting Data Migration: SQLite (jaldrishti.db) -> Supabase PostgreSQL...")

    with engine.begin() as pg_conn:
        # 1. Migrate Users
        sqlite_cur.execute("SELECT * FROM users")
        users = sqlite_cur.fetchall()
        user_count = 0
        for u in users:
            d = dict(u)
            # Parse datetime strings to proper datetime objects if needed
            created_at = datetime.fromisoformat(d['created_at']) if d['created_at'] else datetime.utcnow()
            updated_at = datetime.fromisoformat(d['updated_at']) if d['updated_at'] else datetime.utcnow()
            
            pg_conn.execute(text("""
                INSERT INTO users (id, username, phone_number, hashed_password, is_active, created_at, updated_at)
                VALUES (:id, :username, :phone_number, :hashed_password, :is_active, :created_at, :updated_at)
                ON CONFLICT (id) DO NOTHING
            """), {
                "id": d['id'],
                "username": d['username'],
                "phone_number": d['phone_number'],
                "hashed_password": d['hashed_password'],
                "is_active": bool(d['is_active']),
                "created_at": created_at,
                "updated_at": updated_at
            })
            user_count += 1
        print(f"Migrated {user_count} Users to Supabase.")

        # 2. Migrate User Profiles
        sqlite_cur.execute("SELECT * FROM user_profiles")
        profiles = sqlite_cur.fetchall()
        profile_count = 0
        for p in profiles:
            d = dict(p)
            pg_conn.execute(text("""
                INSERT INTO user_profiles (id, user_id, first_name, last_name, location_name, latitude, longitude, farm_area_acres, interested_crop, farming_experience, preferred_language)
                VALUES (:id, :user_id, :first_name, :last_name, :location_name, :latitude, :longitude, :farm_area_acres, :interested_crop, :farming_experience, :preferred_language)
                ON CONFLICT (id) DO NOTHING
            """), {
                "id": d['id'],
                "user_id": d['user_id'],
                "first_name": d['first_name'],
                "last_name": d['last_name'],
                "location_name": d['location_name'],
                "latitude": d['latitude'],
                "longitude": d['longitude'],
                "farm_area_acres": d['farm_area_acres'],
                "interested_crop": d['interested_crop'],
                "farming_experience": d['farming_experience'],
                "preferred_language": d['preferred_language']
            })
            profile_count += 1
        print(f"Migrated {profile_count} User Profiles to Supabase.")

        # 3. Migrate Password Resets
        sqlite_cur.execute("SELECT * FROM password_resets")
        resets = sqlite_cur.fetchall()
        reset_count = 0
        for r in resets:
            d = dict(r)
            exp_at = datetime.fromisoformat(d['expires_at']) if d['expires_at'] else datetime.utcnow()
            crt_at = datetime.fromisoformat(d['created_at']) if d['created_at'] else datetime.utcnow()
            pg_conn.execute(text("""
                INSERT INTO password_resets (id, phone_number, otp_code, expires_at, is_used, created_at)
                VALUES (:id, :phone_number, :otp_code, :expires_at, :is_used, :created_at)
                ON CONFLICT (id) DO NOTHING
            """), {
                "id": d['id'],
                "phone_number": d['phone_number'],
                "otp_code": d['otp_code'],
                "expires_at": exp_at,
                "is_used": bool(d['is_used']),
                "created_at": crt_at
            })
            reset_count += 1
        print(f"Migrated {reset_count} Password Reset Records to Supabase.")

        # 4. Migrate Farm Plots
        sqlite_cur.execute("SELECT * FROM farm_plots")
        plots = sqlite_cur.fetchall()
        plot_count = 0
        for fp in plots:
            d = dict(fp)
            crt_at = datetime.fromisoformat(d['created_at']) if d['created_at'] else datetime.utcnow()
            upd_at = datetime.fromisoformat(d['updated_at']) if d['updated_at'] else datetime.utcnow()
            pg_conn.execute(text("""
                INSERT INTO farm_plots (id, user_id, name, location_name, latitude, longitude, crop_id, sowing_date, area_acres, is_primary, created_at, updated_at, pump_hp, pump_flow_lps, irrigation_method, soil_type)
                VALUES (:id, :user_id, :name, :location_name, :latitude, :longitude, :crop_id, :sowing_date, :area_acres, :is_primary, :created_at, :updated_at, :pump_hp, :pump_flow_lps, :irrigation_method, :soil_type)
                ON CONFLICT (id) DO NOTHING
            """), {
                "id": d['id'],
                "user_id": d['user_id'],
                "name": d['name'],
                "location_name": d['location_name'],
                "latitude": d['latitude'],
                "longitude": d['longitude'],
                "crop_id": d['crop_id'],
                "sowing_date": d['sowing_date'],
                "area_acres": d['area_acres'],
                "is_primary": bool(d['is_primary']),
                "created_at": crt_at,
                "updated_at": upd_at,
                "pump_hp": d['pump_hp'] if d['pump_hp'] is not None else 5.0,
                "pump_flow_lps": d['pump_flow_lps'] if d['pump_flow_lps'] is not None else 5.0,
                "irrigation_method": d['irrigation_method'] if d['irrigation_method'] else 'flood',
                "soil_type": d['soil_type'] if d['soil_type'] else 'clay_loam'
            })
            plot_count += 1
        print(f"Migrated {plot_count} Farm Plots to Supabase.")

        # 5. Migrate Irrigation Logs
        sqlite_cur.execute("SELECT * FROM irrigation_logs")
        logs = sqlite_cur.fetchall()
        log_count = 0
        for l in logs:
            d = dict(l)
            crt_at = datetime.fromisoformat(d['created_at']) if d['created_at'] else datetime.utcnow()
            pg_conn.execute(text("""
                INSERT INTO irrigation_logs (id, farm_plot_id, applied_mm, applied_date, notes, created_at)
                VALUES (:id, :farm_plot_id, :applied_mm, :applied_date, :notes, :created_at)
                ON CONFLICT (id) DO NOTHING
            """), {
                "id": d['id'],
                "farm_plot_id": d['farm_plot_id'],
                "applied_mm": d['applied_mm'],
                "applied_date": d['applied_date'],
                "notes": d['notes'],
                "created_at": crt_at
            })
            log_count += 1
        print(f"Migrated {log_count} Irrigation Logs to Supabase.")

        # Reset Sequences for PostgreSQL auto-increment IDs
        pg_conn.execute(text("SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE(MAX(id), 1)) FROM users;"))
        pg_conn.execute(text("SELECT setval(pg_get_serial_sequence('user_profiles', 'id'), COALESCE(MAX(id), 1)) FROM user_profiles;"))
        pg_conn.execute(text("SELECT setval(pg_get_serial_sequence('password_resets', 'id'), COALESCE(MAX(id), 1)) FROM password_resets;"))
        pg_conn.execute(text("SELECT setval(pg_get_serial_sequence('farm_plots', 'id'), COALESCE(MAX(id), 1)) FROM farm_plots;"))
        pg_conn.execute(text("SELECT setval(pg_get_serial_sequence('irrigation_logs', 'id'), COALESCE(MAX(id), 1)) FROM irrigation_logs;"))
        print("Reset PostgreSQL auto-increment sequences.")

    sqlite_conn.close()
    print("MIGRATION FINISHED SUCCESSFULLY!")

if __name__ == "__main__":
    migrate()
