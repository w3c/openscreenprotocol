# Open Screen Protocol Capabilities Registry

This registry lists the known protocol capabilities used in the [Open Screen
Protocol](https://webscreens.github.io/openscreenprotocol/).  An Open Screen
agent uses capabilities to inform other agents which protocol messages it
understands.

Capability values 1-999 are reserved for use by the Open Screen Protocol itself.
They are listed here for completeness, but are more fully described in the [Open
Screen Protocol](https://webscreens.github.io/openscreenprotocol/#transport).

## Open Screen Protocol Capabilities

[TODO(Issue #254): Finish the capabilities table.](issues/254)

| Id |     Name                  |         Description         | Message Type IDs      |
|----|---------------------------|-----------------------------|-----------------------|
| 1  | `receive-audio`           | Audio Receiver              | 22                    |
| 2  | `receive-video`           | Video Receiver              | 23                    |
| 3  | `receive-presentation`    | Presentation API Receiver   | 14,16,104,106,109,113 |
| 4  | `control-presentation`    | Presentation API Controller | 15,16,103,105,107,108,110,113,121 |
| 5  | `receive-remote-playback` | Remote Playback Receiver    | 17,115,117,119        |
| 6  | `control-remote-playback` | Remote Playback Controller  | 18,20,21,114,116,118  |
| 7  | `receive-streaming`       | Streaming Receiver          | 24                    |
| 8  | `send-streaming`          | Streaming Sender            |                       |




## Extension Capabilities

This table lists capabilities that other parties have reserved to extend the
core protocol.  Each extension should reserve a range of message type IDs and/or
a list of additional fields that will be added to existing Open Screen
Messages. (The entry below is just an example and not an actual registered
extension.)

| Id   |     Name            | Organization  | Description            | Message Type IDs      |
|------|---------------------|---------------|------------------------|-----------------------|
| 1000 | `frobinate-xyzzy`   | FrobozzCo     | Adds xyzzy capability  | 49-51, 8193-8199      |




