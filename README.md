# A3OS_HACK
A Arma3 mission addon to support "hacking" for data. Requires the AE3 mod.

Simply clone the repo in the root of your mission folder and add the below to your `description.ext`;
```cpp
class CfgFunctions {
#include "A3OS_HACK\CfgFunctions.hpp"
}
```

Before "shipping" the mission, consider deleting the .git folder and the README.md file. This'll reduce mission size :)

