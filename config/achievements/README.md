# Achievement Configuration

This directory contains configuration files for the achievement system.

## Files

- `default.yml`: Contains regular (non-secret) achievements that are visible to users before they earn them.
- `secret.yml.example`: Contains example secret achievements. These are not visible to users until they earn them.
- `secret.yml`: The actual secret achievements used by your instance. This file is gitignored and should not be committed to the repository.

## Setting Up Secret Achievements

To set up secret achievements for your instance:

1. Copy the example file to create your own secret achievements file:
   ```
   cp secret.yml.example secret.yml
   ```

2. Edit `secret.yml` to customize your secret achievements:
   - Modify existing achievements
   - Add new achievements
   - Remove achievements you don't want

3. The `secret.yml` file will be loaded automatically when the application starts.

## Achievement Format

Each achievement is defined with the following attributes:

```yaml
- name: Achievement Name
  description: Description of the achievement
  achievement_type: One of [distance, duration, trips, speed, ownership, special]
  threshold: Numeric value required to earn the achievement
  icon: Emoji or icon character
  badge_color: One of [indigo, green, purple, orange, red, yellow, pink, blue]
  points: Number of points earned
  secret: true/false (should be true for secret achievements)
```

## Notes

- Secret achievements are only revealed to users after they earn them.
- The UI shows a count of remaining secret achievements without revealing what they are.
- You can create instance-specific secret achievements that are unique to your deployment.
