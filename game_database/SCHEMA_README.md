# Game Database Schema

This schema supports:
- Users with regional profile data
- Games metadata
- Scores for leaderboards (global and per-region)
- Optional aggregated stats for best-score queries

## Tables

1. regions
   - code (PK), name
   - Normalizes region values for referential integrity and indexing
2. users
   - id (PK), username (unique), email (unique), region_code (FK regions.code)
   - avatar_url, bio, created_at, updated_at
   - Index: idx_users_region for quick filtering by region
3. games
   - id (PK), name (unique), is_active, description, genre, timestamps
   - Index: idx_games_active for quick active games filtering
4. scores
   - id (PK), user_id (FK users.id), game_id (FK games.id), score, submission_date, region_code (FK regions.code)
   - Indexes:
     - idx_scores_game_score (game_id, score DESC) for top leaderboards
     - idx_scores_user (user_id) for user history
     - idx_scores_region_game (region_code, game_id, score DESC) for regional leaderboards
     - Consider adding idx_scores_submission_date for recent activity feeds
5. user_game_stats (optional aggregation)
   - id (PK), user_id (FK), game_id (FK), best_score, last_played, total_plays
   - Unique constraint (user_id, game_id)
   - Index: idx_stats_best (game_id, best_score DESC) for quick per-game bests

## Usage notes

- For global leaderboards: ORDER BY score DESC WHERE game_id = ?
- For regional leaderboards: WHERE region_code = ? AND game_id = ? ORDER BY score DESC
- For latest submissions: add index on submission_date if needed:
  - MySQL 8+: `CREATE INDEX IF NOT EXISTS idx_scores_submission_date ON scores(submission_date);`
  - MySQL <8: check existence first then create.

## Applying the schema

- The provisioning script will:
  - Ensure database `myapp` exists
  - Create tables with necessary constraints and indexes
- You can reapply with:
  - `mysql -u appuser -pdbuser123 -h localhost -P 5000 < schema.sql`
  - Or using the connection command in `db_connection.txt` and then `SOURCE /path/to/schema.sql;`

## Data integrity

- Deleting a user or a game cascades to their scores and stats.
- Region changes cascade to dependent rows.
- Users’ region set to NULL when the region is deleted.

