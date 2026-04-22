# Custom Skills

Place your custom agent skills in this directory. Each skill should be a subdirectory containing a `SKILL.md` file.

## Directory Structure

```
custom-skills/
  my-skill/
    SKILL.md
  another-skill/
    SKILL.md
```

## SKILL.md Format

```markdown
---
name: My Skill
description: A brief description of what this skill does.
---

# My Skill

Detailed documentation for the skill...
```

## Activation

1. Set the absolute path in `.env`:
   ```
   CUSTOM_SKILLS_HOST_PATH=/absolute/path/to/kimi-agent/custom-skills
   ```

2. Restart the gateway:
   ```bash
   docker-compose up -d
   ```

Custom skills are mounted read-only into every session sandbox at `~/.config/agents/skills` and discovered automatically by the agent.
