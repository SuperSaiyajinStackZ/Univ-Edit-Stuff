# The Sims 2 GBA and NDS Tools

## Checksum-Updater
Update Checksums of your The Sims 2 GBA and NDS Savefile, in case they got corrupted for some reason or you are doing save edits.

![](https://github.com/SuperSaiyajinStackZ/Univ-Edit-Stuff/blob/main/Screenshots/Sims2-Checksum-Updater.png)

### History

**v0.1.0**: Added initial implementation of the Checksum-Updater.

**v0.2.0**: Added Header with informations to the Script.

**v0.3.0**: Added History to the Header and also detect if a The Sims 2 Game Boy Advance Slot exist at all.

**v0.4.0**: Added The Sims 2 Nintendo DS USA and Japanese support. All the versions can be detected by checking the 5th byte on the header with: 0x1F being USA, 0x20 being EUR and 0x21 being JPN.