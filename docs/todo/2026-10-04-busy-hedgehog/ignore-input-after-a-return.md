**Ignore every input for 500ms after the game gets focus back.** Build the window as the README
proposes, with the 500ms as a named constant, and test it headlessly by driving `main.notification()`
as M161's tests do: a press inside the window neither resumes the pause screen nor starts the day
from the day brief, and a press after it does. Then check a real return once in desktop Chrome on
a release export (switch tabs during the day brief and during play, come back with a click on the
page) and say in the pull request which notifications the web build actually delivered, since M161
rests on the engine's documentation for them.
