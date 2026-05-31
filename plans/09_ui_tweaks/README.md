# UI tweaks and small functionality

## Show translation

the response received already has the translation of the tutor response in the user's language
when the user taps the message from the tutor, the translation will be shown below the original response, in a smaller font and different color to differentiate it from the original response, to help the user learn
in the default state, only the original response is shown, and the translation is hidden

## CEFR level indicator + picking

at the top of the conversation screen, there is a CEFR level indicator showing the current level (A1, A2, B1, B2, C1, C2)
when the user taps on the CEFR level indicator, a modal bottom sheet is shown with a list of CEFR levels and their descriptions
the user can scroll through the list and tap on a CEFR level to select it
the conversation does not restart when the CEFR level is changed, but the new level is used for all subsequent messages and responses

## Topic suggestions and picking

at the top of the conversation screen, there is a button "Pick a topic"
when the user taps the button, a list of suggested topics is shown in a modal bottom sheet
the user can scroll through the list and tap on a topic
the user can also enter a topic in a text field at the top of the modal and tap "Apply" to set a custom topic
the conversation does not restart when the topic is changed, but the new topic is used for all subsequent messages and responses
