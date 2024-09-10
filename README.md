### FiveM Duty System Overview

The FiveM Duty System is a simple, standalone resource perfect for roleplay servers. It helps manage on-duty status, logs important actions, and keeps everything organized for a smooth roleplay experience.

### Key Features

1. **Clock In/Out:**
   - Use `/clockin [department] [callsign] [badge]` to start your shift.
   - End your shift with `/clockout` and see how long you were on duty.

2. **Check Who's On Duty:**
   - Use `/onduty` to see who’s currently clocked in and their department.

3. **Kick Off Duty:**
   - Admins can remove someone from duty with `/kickoffduty [playerID]`.
   - All actions are logged to a Discord channel for transparency.

4. **Duty Time:**
   - Use `/dutytime` to check how long you’ve been on duty during your current shift.

5. **911 Command for On-Duty Cops:**
   - On-duty cops can respond to emergency calls with the `/911` command.

### Installation

1. Add the resource to your FiveM server’s resources folder.
2. Update your `server.cfg`:
   ```ini
   add_ace group.(group name) duty.view allow
   add_ace group.(group name) duty.kickoff allow
   add_ace group.(group name) duty.clockout allow
   add_ace group.(group name) duty.clockin allow
   ```

### How to Use

- Players use the commands to manage their duty status.
- Admins with permissions can kick players off duty.
- Duty logs are automatically sent to your Discord channel.

### Customization

You can easily tweak the system to suit your server's needs.
