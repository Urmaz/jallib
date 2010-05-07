/** \file
 *  This C header file was generated by $ANTLR version 3.2 Sep 23, 2009 12:02:23
 *
 *     -  From the grammar source file : tmp_g\\jal.g
 *     -                            On : 2010-05-07 22:15:27
 *     -                 for the lexer : jalLexerLexer *
 * Editing it, at least manually, is not wise. 
 *
 * C language generator and runtime by Jim Idle, jimi|hereisanat|idle|dotgoeshere|ws.
 *
 *
 * The lexer jalLexer has the callable functions (rules) shown below,
 * which will invoke the code for the associated rule in the source grammar
 * assuming that the input stream is pointing to a token/text stream that could begin
 * this rule.
 * 
 * For instance if you call the first (topmost) rule in a parser grammar, you will
 * get the results of a full parse, but calling a rule half way through the grammar will
 * allow you to pass part of a full token stream to the parser, such as for syntax checking
 * in editors and so on.
 *
 * The parser entry points are called indirectly (by function pointer to function) via
 * a parser context typedef pjalLexer, which is returned from a call to jalLexerNew().
 *
 * As this is a generated lexer, it is unlikely you will call it 'manually'. However
 * the methods are provided anyway.
 * * The methods in pjalLexer are  as follows:
 *
 *  -  void      pjalLexer->BIN_LITERAL(pjalLexer)
 *  -  void      pjalLexer->DECIMAL_LITERAL(pjalLexer)
 *  -  void      pjalLexer->HEX_LITERAL(pjalLexer)
 *  -  void      pjalLexer->OCTAL_LITERAL(pjalLexer)
 *  -  void      pjalLexer->CHARACTER_LITERAL(pjalLexer)
 *  -  void      pjalLexer->STRING_LITERAL(pjalLexer)
 *  -  void      pjalLexer->HEX_DIGIT(pjalLexer)
 *  -  void      pjalLexer->ESCAPE_SEQUENCE(pjalLexer)
 *  -  void      pjalLexer->OCTAL_ESCAPE(pjalLexer)
 *  -  void      pjalLexer->WS(pjalLexer)
 *  -  void      pjalLexer->NEOL(pjalLexer)
 *  -  void      pjalLexer->INCLUDE_STMT(pjalLexer)
 *  -  void      pjalLexer->J2CG_COMMENT(pjalLexer)
 *  -  void      pjalLexer->J2C_COMMENT(pjalLexer)
 *  -  void      pjalLexer->LINE_COMMENT(pjalLexer)
 *  -  void      pjalLexer->L__DEBUG(pjalLexer)
 *  -  void      pjalLexer->L__ERROR(pjalLexer)
 *  -  void      pjalLexer->L__WARN(pjalLexer)
 *  -  void      pjalLexer->L_ALIAS(pjalLexer)
 *  -  void      pjalLexer->L_ASM(pjalLexer)
 *  -  void      pjalLexer->L_ASSEMBLER(pjalLexer)
 *  -  void      pjalLexer->L_ASSERT(pjalLexer)
 *  -  void      pjalLexer->L_AT(pjalLexer)
 *  -  void      pjalLexer->L_BIT(pjalLexer)
 *  -  void      pjalLexer->L_BLOCK(pjalLexer)
 *  -  void      pjalLexer->L_BYTE(pjalLexer)
 *  -  void      pjalLexer->L_CASE(pjalLexer)
 *  -  void      pjalLexer->L_CHIP(pjalLexer)
 *  -  void      pjalLexer->L_CODE(pjalLexer)
 *  -  void      pjalLexer->L_CONST(pjalLexer)
 *  -  void      pjalLexer->L_DATA(pjalLexer)
 *  -  void      pjalLexer->L_DWORD(pjalLexer)
 *  -  void      pjalLexer->L_EEPROM(pjalLexer)
 *  -  void      pjalLexer->L_ELSE(pjalLexer)
 *  -  void      pjalLexer->L_ELSIF(pjalLexer)
 *  -  void      pjalLexer->L_END(pjalLexer)
 *  -  void      pjalLexer->L_EXIT(pjalLexer)
 *  -  void      pjalLexer->L_FOR(pjalLexer)
 *  -  void      pjalLexer->L_FOREVER(pjalLexer)
 *  -  void      pjalLexer->L_FUNCTION(pjalLexer)
 *  -  void      pjalLexer->L_FUSEDEF(pjalLexer)
 *  -  void      pjalLexer->L_GET(pjalLexer)
 *  -  void      pjalLexer->L_ID(pjalLexer)
 *  -  void      pjalLexer->L_IF(pjalLexer)
 *  -  void      pjalLexer->L_IN(pjalLexer)
 *  -  void      pjalLexer->L_INLINE(pjalLexer)
 *  -  void      pjalLexer->L_INTERRUPT(pjalLexer)
 *  -  void      pjalLexer->L_IS(pjalLexer)
 *  -  void      pjalLexer->L_LOOP(pjalLexer)
 *  -  void      pjalLexer->L_NOP(pjalLexer)
 *  -  void      pjalLexer->L_OF(pjalLexer)
 *  -  void      pjalLexer->L_OTHERWISE(pjalLexer)
 *  -  void      pjalLexer->L_OUT(pjalLexer)
 *  -  void      pjalLexer->L_PRAGMA(pjalLexer)
 *  -  void      pjalLexer->L_PROCEDURE(pjalLexer)
 *  -  void      pjalLexer->L_PUT(pjalLexer)
 *  -  void      pjalLexer->L_REPEAT(pjalLexer)
 *  -  void      pjalLexer->L_RETURN(pjalLexer)
 *  -  void      pjalLexer->L_SBYTE(pjalLexer)
 *  -  void      pjalLexer->L_SDWORD(pjalLexer)
 *  -  void      pjalLexer->L_SHARED(pjalLexer)
 *  -  void      pjalLexer->L_STACK(pjalLexer)
 *  -  void      pjalLexer->L_SWORD(pjalLexer)
 *  -  void      pjalLexer->L_TARGET(pjalLexer)
 *  -  void      pjalLexer->L_THEN(pjalLexer)
 *  -  void      pjalLexer->L_UNTIL(pjalLexer)
 *  -  void      pjalLexer->L_USING(pjalLexer)
 *  -  void      pjalLexer->L_VAR(pjalLexer)
 *  -  void      pjalLexer->L_VOLATILE(pjalLexer)
 *  -  void      pjalLexer->L_WHILE(pjalLexer)
 *  -  void      pjalLexer->L_WORD(pjalLexer)
 *  -  void      pjalLexer->AMP(pjalLexer)
 *  -  void      pjalLexer->APOSTROPHE(pjalLexer)
 *  -  void      pjalLexer->ASSIGN(pjalLexer)
 *  -  void      pjalLexer->ASTERIX(pjalLexer)
 *  -  void      pjalLexer->BANG(pjalLexer)
 *  -  void      pjalLexer->CARET(pjalLexer)
 *  -  void      pjalLexer->COLON(pjalLexer)
 *  -  void      pjalLexer->COMMA(pjalLexer)
 *  -  void      pjalLexer->EQUAL(pjalLexer)
 *  -  void      pjalLexer->GREATER(pjalLexer)
 *  -  void      pjalLexer->GREATER_EQUAL(pjalLexer)
 *  -  void      pjalLexer->LBRACKET(pjalLexer)
 *  -  void      pjalLexer->LCURLY(pjalLexer)
 *  -  void      pjalLexer->LEFT_SHIFT(pjalLexer)
 *  -  void      pjalLexer->LESS(pjalLexer)
 *  -  void      pjalLexer->LESS_EQUAL(pjalLexer)
 *  -  void      pjalLexer->LPAREN(pjalLexer)
 *  -  void      pjalLexer->MINUS(pjalLexer)
 *  -  void      pjalLexer->NOT_EQUAL(pjalLexer)
 *  -  void      pjalLexer->OR(pjalLexer)
 *  -  void      pjalLexer->PERCENT(pjalLexer)
 *  -  void      pjalLexer->PLUS(pjalLexer)
 *  -  void      pjalLexer->RBRACKET(pjalLexer)
 *  -  void      pjalLexer->RCURLY(pjalLexer)
 *  -  void      pjalLexer->RIGHT_SHIFT(pjalLexer)
 *  -  void      pjalLexer->RPAREN(pjalLexer)
 *  -  void      pjalLexer->SLASH(pjalLexer)
 *  -  void      pjalLexer->IDENTIFIER(pjalLexer)
 *  -  void      pjalLexer->LETTER(pjalLexer)
 *  -  void      pjalLexer->Tokens(pjalLexer)
 *
 * The return type for any particular rule is of course determined by the source
 * grammar file.
 */
// [The "BSD licence"]
// Copyright (c) 2005-2009 Jim Idle, Temporal Wave LLC
// http://www.temporal-wave.com
// http://www.linkedin.com/in/jimidle
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef	_jalLexer_H
#define _jalLexer_H
/* =============================================================================
 * Standard antlr3 C runtime definitions
 */
#include    <antlr3.h>

/* End of standard antlr 3 runtime definitions
 * =============================================================================
 */
 
#ifdef __cplusplus
extern "C" {
#endif

// Forward declare the context typedef so that we can use it before it is
// properly defined. Delegators and delegates (from import statements) are
// interdependent and their context structures contain pointers to each other
// C only allows such things to be declared if you pre-declare the typedef.
//
typedef struct jalLexer_Ctx_struct jalLexer, * pjalLexer;



#ifdef	ANTLR3_WINDOWS
// Disable: Unreferenced parameter,							- Rules with parameters that are not used
//          constant conditional,							- ANTLR realizes that a prediction is always true (synpred usually)
//          initialized but unused variable					- tree rewrite variables declared but not needed
//          Unreferenced local variable						- lexer rule declares but does not always use _type
//          potentially unitialized variable used			- retval always returned from a rule 
//			unreferenced local function has been removed	- susually getTokenNames or freeScope, they can go without warnigns
//
// These are only really displayed at warning level /W4 but that is the code ideal I am aiming at
// and the codegen must generate some of these warnings by necessity, apart from 4100, which is
// usually generated when a parser rule is given a parameter that it does not use. Mostly though
// this is a matter of orthogonality hence I disable that one.
//
#pragma warning( disable : 4100 )
#pragma warning( disable : 4101 )
#pragma warning( disable : 4127 )
#pragma warning( disable : 4189 )
#pragma warning( disable : 4505 )
#pragma warning( disable : 4701 )
#endif

/** Context tracking structure for jalLexer
 */
struct jalLexer_Ctx_struct
{
    /** Built in ANTLR3 context tracker contains all the generic elements
     *  required for context tracking.
     */
    pANTLR3_LEXER    pLexer;


     void (*mBIN_LITERAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mDECIMAL_LITERAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mHEX_LITERAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mOCTAL_LITERAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mCHARACTER_LITERAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mSTRING_LITERAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mHEX_DIGIT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mESCAPE_SEQUENCE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mOCTAL_ESCAPE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mWS)	(struct jalLexer_Ctx_struct * ctx);
     void (*mNEOL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mINCLUDE_STMT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mJ2CG_COMMENT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mJ2C_COMMENT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mLINE_COMMENT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL__DEBUG)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL__ERROR)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL__WARN)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_ALIAS)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_ASM)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_ASSEMBLER)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_ASSERT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_AT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_BIT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_BLOCK)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_BYTE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_CASE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_CHIP)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_CODE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_CONST)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_DATA)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_DWORD)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_EEPROM)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_ELSE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_ELSIF)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_END)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_EXIT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_FOR)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_FOREVER)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_FUNCTION)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_FUSEDEF)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_GET)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_ID)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_IF)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_IN)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_INLINE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_INTERRUPT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_IS)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_LOOP)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_NOP)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_OF)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_OTHERWISE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_OUT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_PRAGMA)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_PROCEDURE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_PUT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_REPEAT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_RETURN)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_SBYTE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_SDWORD)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_SHARED)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_STACK)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_SWORD)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_TARGET)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_THEN)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_UNTIL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_USING)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_VAR)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_VOLATILE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_WHILE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mL_WORD)	(struct jalLexer_Ctx_struct * ctx);
     void (*mAMP)	(struct jalLexer_Ctx_struct * ctx);
     void (*mAPOSTROPHE)	(struct jalLexer_Ctx_struct * ctx);
     void (*mASSIGN)	(struct jalLexer_Ctx_struct * ctx);
     void (*mASTERIX)	(struct jalLexer_Ctx_struct * ctx);
     void (*mBANG)	(struct jalLexer_Ctx_struct * ctx);
     void (*mCARET)	(struct jalLexer_Ctx_struct * ctx);
     void (*mCOLON)	(struct jalLexer_Ctx_struct * ctx);
     void (*mCOMMA)	(struct jalLexer_Ctx_struct * ctx);
     void (*mEQUAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mGREATER)	(struct jalLexer_Ctx_struct * ctx);
     void (*mGREATER_EQUAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mLBRACKET)	(struct jalLexer_Ctx_struct * ctx);
     void (*mLCURLY)	(struct jalLexer_Ctx_struct * ctx);
     void (*mLEFT_SHIFT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mLESS)	(struct jalLexer_Ctx_struct * ctx);
     void (*mLESS_EQUAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mLPAREN)	(struct jalLexer_Ctx_struct * ctx);
     void (*mMINUS)	(struct jalLexer_Ctx_struct * ctx);
     void (*mNOT_EQUAL)	(struct jalLexer_Ctx_struct * ctx);
     void (*mOR)	(struct jalLexer_Ctx_struct * ctx);
     void (*mPERCENT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mPLUS)	(struct jalLexer_Ctx_struct * ctx);
     void (*mRBRACKET)	(struct jalLexer_Ctx_struct * ctx);
     void (*mRCURLY)	(struct jalLexer_Ctx_struct * ctx);
     void (*mRIGHT_SHIFT)	(struct jalLexer_Ctx_struct * ctx);
     void (*mRPAREN)	(struct jalLexer_Ctx_struct * ctx);
     void (*mSLASH)	(struct jalLexer_Ctx_struct * ctx);
     void (*mIDENTIFIER)	(struct jalLexer_Ctx_struct * ctx);
     void (*mLETTER)	(struct jalLexer_Ctx_struct * ctx);
     void (*mTokens)	(struct jalLexer_Ctx_struct * ctx);    const char * (*getGrammarFileName)();
    void	    (*free)   (struct jalLexer_Ctx_struct * ctx);
        
};

// Function protoypes for the constructor functions that external translation units
// such as delegators and delegates may wish to call.
//
ANTLR3_API pjalLexer jalLexerNew         (pANTLR3_INPUT_STREAM instream);
ANTLR3_API pjalLexer jalLexerNewSSD      (pANTLR3_INPUT_STREAM instream, pANTLR3_RECOGNIZER_SHARED_STATE state);

/** Symbolic definitions of all the tokens that the lexer will work with.
 * \{
 *
 * Antlr will define EOF, but we can't use that as it it is too common in
 * in C header files and that would be confusing. There is no way to filter this out at the moment
 * so we just undef it here for now. That isn't the value we get back from C recognizers
 * anyway. We are looking for ANTLR3_TOKEN_EOF.
 */
#ifdef	EOF
#undef	EOF
#endif
#ifdef	Tokens
#undef	Tokens
#endif 
#define J2C_COMMENT      17
#define L__ERROR      20
#define L_USING      34
#define LETTER      110
#define L_INTERRUPT      75
#define L_VAR      61
#define CONDITION      6
#define ASTERIX      62
#define EOF      -1
#define L_CODE      77
#define L__DEBUG      18
#define L_REPEAT      37
#define LBRACKET      23
#define L_DWORD      66
#define L_SBYTE      67
#define CASE_VALUE      5
#define RPAREN      48
#define GREATER      90
#define STRING_LITERAL      19
#define FUNC_PROC_CALL      7
#define NOT_EQUAL      88
#define L_NOP      26
#define CARET      85
#define L_FUSEDEF      82
#define LESS      89
#define BIN_LITERAL      100
#define L_STACK      76
#define VAR      9
#define L_PRAGMA      72
#define BODY      4
#define APOSTROPHE      54
#define L_ELSE      41
#define L_DATA      80
#define L_VOID      10
#define L_CONST      59
#define LINE_COMMENT      109
#define INCLUDE_STMT      15
#define L_VOLATILE      49
#define CHARACTER_LITERAL      60
#define LCURLY      31
#define OCTAL_ESCAPE      106
#define L_GET      57
#define L_END      30
#define L_BYTE      64
#define WS      107
#define L_EXIT      11
#define L_BLOCK      46
#define OR      84
#define LEFT_SHIFT      93
#define LESS_EQUAL      91
#define L_FUNCTION      56
#define L_SHARED      70
#define DECIMAL_LITERAL      103
#define L_THEN      40
#define L_AT      71
#define L_IF      39
#define L_FOREVER      35
#define L_RETURN      13
#define L_ALIAS      58
#define AMP      86
#define L_IS      52
#define L_EEPROM      78
#define L_IN      50
#define L_ASSERT      14
#define J2CG_COMMENT      16
#define L_CHIP      83
#define L_ID      79
#define L_PUT      55
#define LPAREN      47
#define NEOL      108
#define ESCAPE_SEQUENCE      105
#define SLASH      96
#define L_SWORD      68
#define COMMA      27
#define L_CASE      43
#define L_BIT      63
#define IDENTIFIER      99
#define EQUAL      87
#define RIGHT_SHIFT      94
#define PLUS      95
#define HEX_LITERAL      101
#define L_LOOP      12
#define RBRACKET      24
#define L_ELSIF      42
#define PARAMS      8
#define L_ASSEMBLER      28
#define L_FOR      33
#define PERCENT      97
#define L_WORD      65
#define L__WARN      21
#define OCTAL_LITERAL      102
#define HEX_DIGIT      104
#define L_OTHERWISE      45
#define BANG      98
#define MINUS      81
#define L_UNTIL      38
#define COLON      29
#define L_TARGET      73
#define L_WHILE      36
#define L_SDWORD      69
#define L_OUT      51
#define RCURLY      32
#define L_OF      44
#define ASSIGN      22
#define L_PROCEDURE      53
#define L_INLINE      74
#define L_ASM      25
#define GREATER_EQUAL      92
#ifdef	EOF
#undef	EOF
#define	EOF	ANTLR3_TOKEN_EOF
#endif

#ifndef TOKENSOURCE
#define TOKENSOURCE(lxr) lxr->pLexer->rec->state->tokSource
#endif

/* End of token definitions for jalLexer
 * =============================================================================
 */
/** \} */

#ifdef __cplusplus
}
#endif

#endif

/* END - Note:Keep extra line feed to satisfy UNIX systems */
