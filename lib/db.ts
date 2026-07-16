import { Pool } from "pg";

const connectionString = process.env.DATABASE_URL || process.env.POSTGRES_URL;
const isNeon = connectionString ? connectionString.includes("neon.tech") : false;

const pool = new Pool({
  connectionString,
  ssl: isNeon ? {
    rejectUnauthorized: false, // Required for Neon PostgreSQL SSL handshakes
  } : false,
});

export default pool;
export const query = (text: string, params?: unknown[]) => pool.query(text, params);
