/**
 * A grammar describing the C-like preprocessor that is used in the ArmA series
 * 
 * @author: Raven
 */
grammar Preprocessor;

@header {
	package raven.sqdev.editors.parser.preprocessor;
}

start  : 
	(preprocessorStatement (NL+ preprocessorStatement)*
	| other)* EOF
;

	preprocessorStatement:
		include
		| define
		| undefine
		| prepIf
		| error
	;
	
		include:
			INCLUDE file=STRING
		;
		
		define:
			DEFINE name=ID macroArgs? (~(NL | EOF))*
		;
		
			macroArgs:
				LPAREN ID (COMMA ID)* RPAREN
			;
		
		undefine:
			UNDEFINE ID
		;
		
		prepIf:
			(IF | IFN) ID (NL+ preprocessorStatement)*? NL+ (ELSE (NL+ preprocessorStatement)*)? NL* ENDIF
		;
		
		error:
			PREP_PREFIX instruction=(ID | STRING) (~(NL | EOF))*
		;
		
	other:
		NL
		| .+? (NL | EOF)
	;


COMMENT: ('//' .*? '\n' | '/*' .*? '*/') -> skip ; // skip comments
WS : ([ \t\r] | '\\\n')+ -> skip ; // skip spaces, tabs and escaped newlines

PREP_PREFIX: '#' ;
NL: '\n' ;

INCLUDE: '#include' ;
DEFINE: '#define' ;
UNDEFINE: '#undef' ;
IF: '#ifdef' ;
IFN: '#ifndef' ;
ELSE: '#else' ;
ENDIF: '#endif' ;

LPAREN: '(' ;
RPAREN: ')' ;
COMMA: ',' ;

STRING: '"' .*? '"' | '\'' .*? '\'' ;
ID: (LETTER | INT | '_')+ ;
LETTER: [a-zA-Z_] ;
INT: [0-9]+ ;

OTHER: . ;