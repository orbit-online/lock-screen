# lock-screen

A small tool to lock the screen unless a key is held

## Dependencies

- evtest
- notify-send
- dbus-launch
- sudo

## Usage

```
lock-screen - Lock the screen unless a key is held
Usage:
  lock-screen [options] USERNAME TIMEOUT REASON

Options:
  --key EV_KEY      Which key to hold [default: KEY_LEFTSHIFT]
                    (Use \`evtest /dev/input/event<NUM>\` to see available keys)
  --key-desc DESC   Description of the key [default: shift]
                    (unless --key is specified)

Note:
  USERNAME is the name of the user that should be notified
  TIMEOUT is the time in seconds (e.g. 1.5) to allow the user to hold --key
    before locking the screen
  REASON is the reason for why the screen is being locked and will be the
    notification title
```
