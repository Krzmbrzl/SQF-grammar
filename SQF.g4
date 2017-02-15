/**
 * This is the grammar for the SQF scripting language used in the games of Bohemia Interactive 
 * (such as ArmA 3 for instance). It is based on the work of Foxhound International's publications on the topic
 * of SQF precedence (https://foxhound.international/precedence-arma-3-sqf.html) and his publication about 
 * the SQF grammar (https://foxhound.international/arma-3-sqf-grammar.html)
 * 
 * @author: Raven
 */
 
grammar SQF;

@lexer::header {
	package raven.sqdev.editors.sqfeditor.parsing;
	
	import java.util.List;
}

@lexer::members {
	
	protected List<String> binaryOperators;
	protected List<String> unaryOperators;
	protected List<String> macroNames;
	
	
	public SQFLexer(CharStream input, List<String> binaryOperators, List<String> unaryOperators, List<String> macroNames) {
		this(input);
		
		// make operators lowercase
		for(int i=0; i<binaryOperators.size(); i++) {
			binaryOperators.set(i, binaryOperators.get(i).toLowerCase());
		}
		for(int i=0; i<unaryOperators.size(); i++) {
			unaryOperators.set(i, unaryOperators.get(i).toLowerCase());
		}
		
		this.binaryOperators = binaryOperators;
		this.unaryOperators = unaryOperators;
		this.macroNames = macroNames;
	}
}

@parser::header {
	package raven.sqdev.editors.sqfeditor.parsing;
}

tokens{MACRO_NAME, UNARY_OPERATOR}

start:
	code EOF
;

code:
	(statement semicolon=SEMICOLON?)* statement?
;
	
	macro:
		MACRO_NAME (R_B_O macroArgument (COMMA macroArgument)* R_B_C)?
	;
	
		macroArgument:
			(R_B_O macroArgument R_B_C | ~(COMMA | R_B_C ))*?
		;

	statement:
		assignment
		| binaryExpression
		| SEMICOLON //empty statement
	;
	
		assignment:
			(PRIVATE)? (ID | macro) EQUALS (binaryExpression | macro)
		;
		
		binaryExpression:
			binaryExpression POWER binaryExpression // note that the '^' operator is left-associative
			| binaryExpression OPERATOR_PRECEDENCE_MULTIPLY binaryExpression
			| binaryExpression OPERATOR_PRECEDENCE_ADD binaryExpression
			| binaryExpression ELSE binaryExpression
			| binaryExpression BINARY_OPERATOR binaryExpression //TODO: check before primaryExpression
			| binaryExpression COMPARE_PRECEDENCE_OPERATOR binaryExpression
			| binaryExpression AND binaryExpression
			| binaryExpression OR binaryExpression
			| BINARY_OPERATOR primaryExpression[false] // binary operator used as unary operator
			| OPERATOR_PRECEDENCE_ADD primaryExpression[false] // used as punctuation
			| BINARY_OPERATOR // binary operator used as nular operator
			| primaryExpression[false]
		;
		
			primaryExpression[boolean allowBinaryAlts]:
				macro
				| unaryExpression [allowBinaryAlts]
				| nularExpression
			;
			
				nularExpression:
					operator												#NularOperator
					| NUMBER												#Number
					| STRING												#String
					| C_B_O code C_B_C									#InlineCode
					| S_B_O (binaryExpression (COMMA binaryExpression)* )? S_B_C	#Array
					| R_B_O binaryExpression? R_B_C							#Parenthesis
					| commonError											#Error
				;
				
					// Some common errors
					commonError:
						C_B_O code {notifyErrorListeners("Missing closing '}'");}
						| C_B_O code C_B_C C_B_C {notifyErrorListeners("Too many curly brackets!");}
						| S_B_O binaryExpression? {notifyErrorListeners("Missing closing ']'");}
						| S_B_O binaryExpression? S_B_C S_B_C {notifyErrorListeners("Too many square brackets!");}
						| R_B_O binaryExpression? {notifyErrorListeners("Missing closing ')'");}
						| R_B_O binaryExpression? R_B_C R_B_C {notifyErrorListeners("Too many parentheses!");}
					;
				
				unaryExpression [boolean allowBinaryAlts]:
					(UNARY_OPERATOR | PUCTUATION_OTHER) primaryExpression[true] 
					| {$allowBinaryAlts}? BINARY_OPERATOR primaryExpression[true] // binary operator used as unary operator
					| PRIVATE primaryExpression[false]
				;
				
					operator:
						ID
						| punctuation
					;
					
						punctuation:
							PUCTUATION_OTHER
						;





//////////////////////////////LEXER//////////////////////////////////////////
OPERATOR_PRECEDENCE_MULTIPLY: '*' | '/'  | '%' | 'mod' ;
OPERATOR_PRECEDENCE_ADD: '+' | '-' | 'min' | 'max' ;
PUCTUATION_OTHER: '!' ;

OR: '||' ;
AND: '&&' ;
COMPARE_PRECEDENCE_OPERATOR: '==' | '!=' | '<' | '>' | '<=' | '>=' | '>>' ;
ELSE: E L S E ;
POWER: '^' ;

SEMICOLON: ';' ;
COMMA: ',' ;
EQUALS: '=' ;
PRIVATE: P R I V A T E ;

MACRO_DECLARATION: (('#ifdef' | '#ifndef') .*? '#endif'
	|'#' (~'\n' | ' \\\n')* '\n'
) ->skip ;

WHITESPACE: [ \r\n\t]+ -> skip ;
COMMENT: ('//' .*? ('\n' | EOF) | '/*' .*? '*/') -> skip ;

NUMBER: (INT+ ('.' INT+)? | ('0x' | '$') (INT | LETTER)+) 
				('e' ('-')? (INT+ ('.' INT+)? | ('0x' | '$') (INT | LETTER)+))? ;

ID: (LETTER | INT | '_')+ {
	if (macroNames.contains(getText())) {
		// it's not an ID but a macro name
		setType(SQFParser.MACRO_NAME);
	} else {
		if (binaryOperators.contains(getText().toLowerCase())) {
			// it's not an ID but a binary operator
			setType(SQFParser.BINARY_OPERATOR);
		} else {
			if(unaryOperators.contains(getText().toLowerCase())) {
				// it's not an ID but a unary operator
				setType(SQFParser.UNARY_OPERATOR);
			}
		}
	}
};

BINARY_OPERATOR: ':' ;

STRING: '"' (~'"' | '""')* '"' | '\'' (~'\'' | '\'\'')* '\'';

C_B_O: '{' ;
C_B_C: '}' ;
S_B_O: '[' ;
S_B_C: ']' ;
R_B_O: '(' ;
R_B_C: ')' ;

OTHER: .+? ;

fragment LETTER: [A-Za-z] ;
fragment INT: [0-9] ;

fragment A: 'a' | 'A' ;
fragment E: 'e' | 'E' ;
fragment P: 'p' | 'P' ;
fragment L: 'l' | 'L' ;
fragment R: 'r' | 'R' ;
fragment S: 's' | 'S' ;
fragment T: 't' | 'T' ;
fragment I: 'i' | 'I' ;
fragment V: 'v' | 'V' ;