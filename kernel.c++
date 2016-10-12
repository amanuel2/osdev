#include <stdarg.h>
#include <stdint.h>


void printf(char* str)
{
    static unsigned short* VideoMemory = (unsigned short*)0xb8000;

    for(int i = 0; str[i] != '\0'; ++i)
        VideoMemory[i] = (VideoMemory[i] & 0xFF00) | str[i];
}

namespace stkl
{

	class printkc 
	{
  		public:
    		printkc() = default;
    		printkc& operator<<(char* input) {
      			printf(input);
      			return *this;
    		}
	};

	printkc printk;
}
//Call all class constructor
//for global objects before
//calling the kernel
typedef void (*constructor)();
extern "C" constructor start_ctors;
extern "C" constructor end_ctors;
extern "C" void callConstructors()
{
    for(constructor* i = &start_ctors; i != &end_ctors; i++)
        (*i)();
}



extern "C" void kernelMain(void* multiboot_structure,uint32_t magicnumber)
{
  stkl::printk << "Hello";
   while(1);	
}

