/**
 * Copyright 2012-2015 Niall Gallagher
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
grammar CQSqlGrammarExt;
import SQLite;

start : K_SELECT result_column_simple (',' result_column_simple )* K_FROM indexedCollection whereClause? groupByClause? orderByClause? limitClause? EOF ;

indexedCollection : IDENTIFIER | STRING_LITERAL ;
whereClause : K_WHERE query ;
orderByClause : K_ORDER K_BY attributeOrder ( ',' attributeOrder )* ;

groupByClause: K_GROUP K_BY IDENTIFIER;
limitClause : K_LIMIT NUMERIC_LITERAL;

result_column_simple
 : expr ( K_AS? column_alias )?
 | countClause
 | histogramClause
 ;

expr
 : STAR
 | literal_value
// | BIND_PARAMETER
 | column_name
// | unary_operator expr
// | expr '||' expr
 | expr ( '*' | '/' | '%' ) expr
 | expr ( '+' | '-' ) expr
 | expr ( '<<' | '>>' | '&' | '|' ) expr
 | expr ( '<' | '<=' | '>' | '>=' ) expr
 | expr ( '=' | '==' | '!=' | '<>' | K_IS | K_IS K_NOT | K_IN | K_LIKE | K_GLOB | K_MATCH | K_REGEXP ) expr
// | expr K_AND expr
// | expr K_OR expr
 | function_name '(' ( K_DISTINCT? expr ( ',' expr )* | '*' )? ')'
 | '(' expr ')'
// | K_CAST '(' expr K_AS type_name ')'
// | expr K_COLLATE collation_name
// | expr K_NOT? ( K_LIKE | K_GLOB | K_REGEXP | K_MATCH ) expr ( K_ESCAPE expr )?
// | expr ( K_ISNULL | K_NOTNULL | K_NOT K_NULL )
// | expr K_IS K_NOT? expr
// | expr K_NOT? K_BETWEEN expr K_AND expr
// | expr K_NOT? K_IN ( '(' ( select_stmt
//                          | expr ( ',' expr )*
//                          )?
//                      ')'
//                    | ( database_name '.' )? table_name )
// | ( ( K_NOT )? K_EXISTS )? '(' select_stmt ')'
 | K_CASE expr? ( K_WHEN expr K_THEN expr )+ ( K_ELSE expr )? K_END
// | raise_function
 ;

column_name
 : any_name
 ;

any_name
 : IDENTIFIER
 | keyword
 | STRING_LITERAL
 | '(' any_name ')'
 ;

literal_value
 : NUMERIC_LITERAL
 | STRING_LITERAL
 | BLOB_LITERAL
 | K_NULL
 | K_CURRENT_TIME
 | K_CURRENT_DATE
 | K_CURRENT_TIMESTAMP
 ;

column_alias
 : IDENTIFIER
 | STRING_LITERAL
 ;

histogramClause: F_HISTOGRAM '(' NUMERIC_LITERAL ')' ;
countClause
	: F_COUNT '(' F_HLL? K_DISTINCT column_name (',' column_name)* ')'
	| F_COUNT '(' STAR ')'
	;

query : logicalQuery | simpleQuery ;

logicalQuery : andQuery | orQuery | notQuery ;

andQuery : OPEN_PAR query K_AND query (K_AND query)* CLOSE_PAR ;
orQuery : OPEN_PAR query K_OR query (K_OR query)* CLOSE_PAR ;
notQuery : K_NOT query ;

simpleQuery : equalQuery
            | notEqualQuery
            | lessThanOrEqualToQuery
            | lessThanQuery
            | greaterThanOrEqualToQuery
            | greaterThanQuery
            | betweenQuery
            | notBetweenQuery
            | inQuery
            | notInQuery
            | startsWithQuery
            | endsWithQuery
            | containsQuery
            | hasQuery
            | notHasQuery
            | OPEN_PAR simpleQuery CLOSE_PAR
            ;

equalQuery : attributeName ASSIGN queryParameter ;
notEqualQuery : attributeName NOT_EQ2 queryParameter ;
lessThanOrEqualToQuery : attributeName LT_EQ queryParameter ;
lessThanQuery : attributeName LT queryParameter ;
greaterThanOrEqualToQuery : attributeName GT_EQ queryParameter ;
greaterThanQuery : attributeName GT queryParameter ;
betweenQuery : attributeName K_BETWEEN queryParameter K_AND queryParameter ;
notBetweenQuery : attributeName K_NOT K_BETWEEN queryParameter K_AND queryParameter ;
inQuery : attributeName K_IN OPEN_PAR queryParameter (',' queryParameter)* CLOSE_PAR ;
notInQuery : attributeName K_NOT K_IN OPEN_PAR queryParameter (',' queryParameter)* CLOSE_PAR ;
startsWithQuery : attributeName K_LIKE queryParameterTrailingPercent ;
endsWithQuery : attributeName K_LIKE queryParameterLeadingPercent ;
containsQuery : attributeName K_LIKE queryParameterLeadingAndTrailingPercent ;
hasQuery : attributeName K_IS K_NOT K_NULL ;
notHasQuery : attributeName K_IS K_NULL ;

attributeName : IDENTIFIER | STRING_LITERAL ;

queryParameterTrailingPercent : STRING_LITERAL_WITH_TRAILING_PERCENT ;
queryParameterLeadingPercent : STRING_LITERAL_WITH_LEADING_PERCENT ;
queryParameterLeadingAndTrailingPercent : STRING_LITERAL_WITH_LEADING_AND_TRAILING_PERCENT ;
queryParameter : NUMERIC_LITERAL | STRING_LITERAL ;

STRING_LITERAL_WITH_TRAILING_PERCENT : '\'' ( ~[%'] | '\'\'' )* '%\'' ;
STRING_LITERAL_WITH_LEADING_PERCENT : '\'%' ( ~[%'] | '\'\'' )* '\'' ;
STRING_LITERAL_WITH_LEADING_AND_TRAILING_PERCENT : '\'%' ( ~[%'] | '\'\'' )* '%\'' ;

attributeOrder : attributeName direction? ;
direction : K_ASC | K_DESC ;

F_HISTOGRAM: H I S T O G R A M;
F_COUNT: C O U N T;
F_HLL: H L L;

