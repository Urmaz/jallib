//-----------------------------------------------------------------------------
// Title: jaltarget.h  - target header of 'Just Another Translator'.
//-----------------------------------------------------------------------------
//
// Adapted-by: Joep Suijs
// Compiler: 
//
// This file is part of jallib (http://jallib.googlecode.com)
// Released under the ZLIB license (http://www.opensource.org/licenses/zlib-license.html)
//
// Description: This file contains definitions (and code) required by JAT
//              output to compile for any target system.
//
//-----------------------------------------------------------------------------


// some notes on calling, will be removed...
//    note: param is used for arrays only. leave it out for now
//       void (*put)(struct ByCall_stuct *s, int Param, int Value) ;
//       int  (*get)(struct ByCall_stuct *s, int Param) ;       
//       ( alpha__bc->get ?(*alpha__bc->get)(alpha__bc, alpha__p) :  ( alpha__bc->data ? *(uint8_t *)alpha__bc->data : 0)));


//-----------------------------------------------------------------------------
// The ByCall struct describes how to call a specific pseudo var or volatile
// variable type. The actuall pointer to this var is passed seperatley so the
// same variables can share a ByCall struct.
//-----------------------------------------------------------------------------
typedef struct ByCall_stuct {
   void     (*put)(const struct ByCall_stuct *s, char* Addr, int Value) ;
   uint32_t (*get)(const struct ByCall_stuct *s, char* Addr) ;
   int   Size; // size of type in bytes (round up)
   char  v1;     // var1, implementation-dependent
   char  v2;     // var2, implementation-dependent
} ByCall;


#define PVAR_GET(type, bc, p)    \
(                                \
   bc->get ?                     \
      (*bc->get)(bc, p)          \
   :                             \
      0                          \
)                                \
                                               
#define PVAR_ASSIGN(type, bc, p, expr)        \
   if (bc->put) (*bc->put)(bc, p, expr)

//#define PVAR_DIRECT (ByCall *)NULL, (char *)NULL                                               


void     byte__put(const ByCall *bc, void *Addr, uint32_t Data)   {
   if (Addr) {
       *(uint8_t  *)Addr = (uint8_t)   Data; 
   }
}
    
uint32_t byte__get(const ByCall *bc, void *Addr)                  { 
   if (Addr) {
      return (uint32_t)  *(uint8_t  *)Addr; 
   } else {
      return 0;
   }
}


// marco to check bounderies on array write. Read boundaries are not
// checked (mostly no harm done and wrong index returns unexpected 
// info anyway)
#define DIRECT_ARRAY_ASSIGN(name, index, size, expr)  \
   {if ((index>=0) && (index<size)) name[index]=expr;}

// count definition (for direct access vars). 
// Note:t ## indicates name has to be appended by __size without space.
#define count(name) name##__size


void     word__put(const ByCall *bc, void *Addr, uint32_t Data)   { *(uint16_t *)Addr = (uint16_t)  Data; }
uint32_t word__get(const ByCall *bc, void *Addr)                  { return (uint32_t)  *(uint16_t *)Addr; }

void     dword__put(const ByCall *bc, void *Addr, uint32_t Data)  { *(uint32_t *)Addr = (uint32_t)  Data; }
uint32_t dword__get(const ByCall *bc, void *Addr)                 { return (uint32_t)  *(uint32_t *)Addr; }


const ByCall bc_byte  = { (void *) &byte__put, (void *) &byte__get, 1, 0, 0};
const ByCall bc_word  = { (void *) &word__put, (void *) &word__get, 2, 0, 0};
const ByCall bc_dword = { (void *)&dword__put, (void *)&dword__get, 4, 0, 0};


#define VARBITPUT(name, bitnr)                              \
   void name(const ByCall *s, void *Addr, uint32_t Value)   \
   {                                                        \
      if (Value) {                                          \
         *(uint8_t *)Addr |= (1<<bitnr);                    \
      } else {                                              \
         *(uint8_t *)Addr &= ~(1<<bitnr);                   \
      }                                                     \
   }                                                        \

#define VARBITGET(name, bitnr)                              \
   uint32_t name(const ByCall *s, void *Addr)               \
   {                                                        \
      return (*(uint8_t *)Addr) & (1<<bitnr) ? 1 : 0 ;      \
   }                                                        \


//VARBITSPUT(varbits01__put, 0, 1)
VARBITPUT(varbit0__put, 0);
VARBITPUT(varbit1__put, 1);
VARBITPUT(varbit2__put, 2);
VARBITPUT(varbit3__put, 3);
VARBITPUT(varbit4__put, 4);
VARBITPUT(varbit5__put, 5);
VARBITPUT(varbit6__put, 6);
VARBITPUT(varbit7__put, 7);

VARBITGET(varbit0__get, 0);
VARBITGET(varbit1__get, 1);
VARBITGET(varbit2__get, 2);
VARBITGET(varbit3__get, 3);
VARBITGET(varbit4__get, 4);
VARBITGET(varbit5__get, 5);
VARBITGET(varbit6__get, 6);
VARBITGET(varbit7__get, 7);


// 01 means start with bit 0, 1 bit of size, so we can
// have up to 36 of there functions if we limit ourself to one byte.
//
// values are always passed in the lower bits
//void bitvar01__put(const ByCall *s, void *Addr, uint32_t Value)
//{
//   if (Value) {
//      *(uint8_t *)Addr |= 0x01;
//   } else {
//      *(uint8_t *)Addr &= 0xFE;
//   }
//}
//
//uint32_t  bitvar01__get(const struct ByCall_stuct *s, void* Addr) 
//{ 
//   return (*(uint8_t *)Addr) & 0x01 ? 1 : 0 ; 
//}
//

