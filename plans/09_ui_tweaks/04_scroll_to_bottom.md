# scroll to bottom

when the user sends a message, the conversation should automatically scroll to the bottom to show the latest messages and responses
and same for any action that creates content at the bottom of the conversation, such as showing the translation, receiving a response from the tutor, ...
and also when opening the keyboard

smooth scroll so that latest content is on the screen
 
only exception: if the user has manually scrolled up to read previous messages, then we should not scroll to the bottom when new messages or responses are received, to avoid interrupting the user reading previous content
in this case, we can render a "arrows down" button that the user can tap to scroll to the bottom
