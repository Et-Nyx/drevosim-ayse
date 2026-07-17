# PS4 FTP Client — User's Guide

A guide to using traditional FTP clients to communicate with your PlayStation 4's homebrew FTP server at **`192.168.15.200:2121`**.

Traditional FTP clients do not mount filesystems, meaning they are completely stable and will never cause system or desktop freezes.

---

## 1. FileZilla (GUI)

For full graphical drag-and-drop file transfers:

1. Launch **FileZilla** from your desktop application launcher.
2. In the top Quickconnect bar, enter:
   - **Host**: `192.168.15.200`
   - **Port**: `2121`
   - **Username**: `anonymous` (or leave empty)
3. Click **Quickconnect**.
4. You will see your local files on the left and the PS4 filesystem partitions on the right. You can now drag and drop files back and forth.

---

## 2. Command-Line Helpers (lftp)

The configuration module adds several convenient, fast shell aliases for terminal operations:

### View files on PS4
```bash
ps4-ls
```
Lists the directories and files in the root partition of the PS4.

### Upload a file to the PS4 `/data` partition
```bash
ps4-push <local-file>
```
Sends a local file directly to `/data/` on the PS4.

### Download a file from the PS4
```bash
ps4-pull <remote-file-path>
```
Downloads the specified file from the PS4 to your current local directory.

### Interactive CLI session
```bash
ps4-ftp
```
Opens an interactive, feature-rich `lftp` session where you can navigate (`cd`), download (`get`), upload (`put`), and delete (`rm`) files interactively. Type `exit` to close the session.
