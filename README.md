# FiveM Duty System

Description

The FiveM Duty System is a standalone resource designed for roleplaying servers. It provides essential features for managing on-duty status, logging duty-related actions, and ensuring smooth roleplay experiences for players.

### Features

1. **Clock-In and Clock-Out Commands:**
   - Players can use `/clockin [department] [badge]` to start their duty shift.
   - `/clockout` allows players to end their duty shift and calculates the duration.

2. **On-Duty Status:**
   - Players can check who is currently on duty using the `/onduty` command.
   - The system tracks on-duty players and their respective departments.

3. **Kick-Off Duty:**
   - Admins or supervisors can use `/kickoffduty [playerID]` to remove a player from duty.
   - Discord webhook logs capture these actions for transparency.

4. **Discord Webhook Logging:**
   - All duty-related events (clock-in, clock-out, kick-off) are logged to a designated Discord channel.
   - Webhook integration ensures real-time updates for staff members.

### Installation

1. Add the resource to your FiveM server resources folder.
2. Update your `server.cfg` file:
   ```ini
   add_ace group.(group name) duty.view allow
   add_ace group.(group name) duty.kickoff allow
   add_ace group.(group name) duty.clockout allow
   add_ace group.(group name) duty.clockin allow
   ```

### Usage

1. Players can use the specified commands to manage their duty status.
2. Admins or supervisors with the appropriate permissions can kick players off duty.
3. Check the Discord channel for duty-related logs.

### Customization

Feel free to customize the system to match your server's specific needs. You can modify messages, add more departments, or integrate additional features.
