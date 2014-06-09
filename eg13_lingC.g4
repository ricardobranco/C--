/*
* Linguagem de Programação Imperativa tipo C
* ano letivo 13/14
*/

grammar eg13_lingC;

@header{
  import java.util.*;
}

@members{
  abstract class Entry{
    String id;
    int level;
    String type;
    boolean pointer = false;
  }

  class Constant extends Entry{
    String value;
  }

  class Typedef extends Entry{
    Integer size;
    HashMap<String,Entry> fields = new HashMap<>();
  }

  class Variable extends Entry{
    String address;
  }

  class Function extends Entry{
    String name;
  }

  class Table extends Entry{
    HashMap<String,Entry> entries = new HashMap<>();

    void removeEntries(int level){
      Iterator<String> iterator = entries.keySet().iterator();
      while(iterator.hasNext()){
        String s = iterator.next();
        if(entries.get(s).level == level)
          iterator.remove();
      }
    }

  }
}

programa  @init{
            Table table = new Table();

            Typedef entry_int = new Typedef();
            Typedef entry_char = new Typedef();
            Typedef entry_float = new Typedef();
            Typedef entry_double = new Typedef();

            entry_int.id = "int";
            entry_int.type = "int";

            entry_char.id = "char";
            entry_char.type = "char";

            entry_float.id = "float";
            entry_float.type = "float";

            entry_double.id = "double";
            entry_double.type = "double";

            table.entries.put(entry_int.id,entry_int);
            table.entries.put(entry_char.id,entry_char);
            table.entries.put(entry_float.id,entry_float);
            table.entries.put(entry_double.id,entry_double);
          }
          @after{
            for(String s: table.entries.keySet()){
              Entry e = table.entries.get(s);
              System.out.println("("+e.getClass().getSimpleName()+") "+s+" -> "+e.type);
            }
          }
          : declaracoes[table] funcoes[table]
          ;

declaracoes  [Table table_IN]
             : declconsts[$table_IN] decltipos[$declconsts.table_OUT] declvariaveis[$decltipos.table_OUT,0,null]
             ;

declconsts  [Table table_IN]
            returns [Table table_OUT]
            : (declconst[$table_IN] ';')*
            {$table_OUT = $table_IN;}
            ;

declconst  [Table table_IN]
           : 'define' idC exp
           {
             Entry entry = new Constant();
             entry.id = $idC.text;
             if($table_IN.entries.containsKey(entry.id))
               System.err.println("Múltipla declaração de "+entry.id);
             else
               $table_IN.entries.put(entry.id,entry);
           }
           ;

decltipos  [Table table_IN]
           returns [Table table_OUT]
           : (decltipo[table_IN] ';')*
           {$table_OUT = $table_IN;}
           ;

decltipo  [Table table_IN]
          @init{Entry entry = new Typedef();}
          @after{$table_IN.entries.put(entry.id,entry);}
          : 'typedef' idT tipoAvancado[entry]
          {
            entry.type = $idT.text;
            if($table_IN.entries.containsKey(entry.type))
              System.err.println("Múltipla declaração do tipo "+entry.type);
          }
          | 'typedef' 'struct' idT '{' declvariaveis[$table_IN,0,entry] '}' tipoAvancado[entry]
          {
            entry.type = $idT.text;
            if($table_IN.entries.containsKey(entry.type))
              System.err.println("Múltipla declaração do tipo "+entry.type);
          }
          ;

funcoes  [Table table_IN]
         : funcao[$table_IN]+
         ;

funcao  [Table table_IN]
        @after{$table_IN.removeEntries(1);}
        : cabecfuncao[$table_IN] corpofuncao
        ;

cabecfuncao  [Table table_IN]
             @init{Entry entry = new Function();}
             @after{$table_IN.entries.put(entry.id,entry);}
             : idT idF
             {
               entry.id = $idF.text;
               entry.type = $idT.text;

               if($table_IN.entries.containsKey(entry.type)){
                 Entry entry_found = $table_IN.entries.get(entry.type);
                 if(!entry_found.getClass().getSimpleName().equals("Typedef")){
                   System.out.println(entry.type+" não é um tipo");
                 }
               }else{
                 System.out.println("Tipo "+entry.type+" desconhecido");
               }

               if($table_IN.entries.containsKey(entry.id)){
                 System.err.println("Múltipla declaração da função "+entry.id);
               }

             }
             '(' parametros[$table_IN]? ')'
             ;

parametros  [Table table_IN]
            : parametro[$table_IN] (',' parametro[$table_IN])* ;

parametro  [Table table_IN]
           : idT idP
           {
             Entry entry = new Variable();
             entry.id = $idP.text;
             entry.level = 1;
             entry.type = $idT.text;
             if($table_IN.entries.containsKey(entry.id)){
               System.err.println("Múltipla declaração do termo "+entry.id);
             }else{
               $table_IN.entries.put(entry.id,entry);
             }
           }
           ;

corpofuncao : '{' declvariaveis[new Table(),0,null] instrucoes '}'
;

declvariaveis  [Table table_IN, int level,Entry struct]
               returns [Table table_OUT]
               : (declvariavel[$table_IN,$level,$struct] ';')*
               {$table_OUT = $table_IN;}
               ;

declvariavel  [Table table_IN, int level, Entry struct]
              : idT
              {
                if($table_IN.entries.containsKey($idT.text)){
                  Entry entry_found = $table_IN.entries.get($idT.text);
                  if(!entry_found.getClass().getSimpleName().equals("Typedef")){
                    System.out.println($idT.text+" não é um tipo");
                  }
                }else{
                  System.out.println("Tipo "+$idT.text+" desconhecido");
                }
              }
              listadcls[$table_IN,level,$idT.text,$struct]
              ;

listadcls  [Table table_IN, int level, String type,Entry struct]
           : dcl[$table_IN,$level,$type,$struct] (',' dcl[$table_IN,$level,$type,$struct])*
           | '(' idV
           {
             Entry entry = new Variable();
             entry.id = $idV.text;
             entry.level = $level;
             entry.type = $type;
             if($struct == null){
               $table_IN.entries.put(entry.id,entry);
             }else{
               ((Typedef) struct).fields.put(entry.id,entry);
             }

           }
           (',' idV
           {
             Entry entryRec = new Variable();
             entryRec.id = $idV.text;
             entryRec.level = $level;
             entryRec.type = $type;
             if($struct == null){
               $table_IN.entries.put(entryRec.id,entryRec);
             }else{
               ((Typedef) struct).fields.put(entryRec.id,entryRec);
             }
           }
           )* ')' '=' exp
           ;

dcl  [Table table_IN, int level, String type,Entry struct]
     : idV
     {
       Entry entry = new Variable();
       entry.id = $idV.text;
       entry.level = $level;
       entry.type = $type;
       if($struct == null){
         $table_IN.entries.put(entry.id,entry);
       }else{
         ((Typedef) struct).fields.put(entry.id,entry);
       }
     }
     ('=' exp)?
     | idV '[' conste ']'
     {
       Entry entry = new Variable();
       entry.id = $idV.text;
       entry.level = $level;
       entry.type = $type;
       if($struct == null){
         $table_IN.entries.put(entry.id,entry);
       }else{
         ((Typedef) struct).fields.put(entry.id,entry);
       }
     }
     ;

tipoAvancado  [Entry entry]
              : ('*')? {$entry.pointer = true;}
              idT {$entry.id = $idT.text;}
              ('[' conste ']'
              {
                ((Typedef) entry).size = $conste.value;
              }
              )?
              ;

/* Instruções --------------------------------------------------------------- */

instrucoes : (instrucao ';')+ ;

instrucao  : atrib
           | invocFunc
           | controlo
           | leitura
           | escrita
           ;

atrib      : idV '=' exp;

invocFunc  : idF '(' exps? ')';

exps       : exp ( ',' exp)*;

exp        : termo
| exp OPAD termo?
;

termo      : fator
| termo OPMUL fator;

fator      : conste
| invocFunc
| idV
| '(' exp ')'
| idV '[' conste ']'
;

leitura    : 'read' '(' vars  ')' ;

vars       : idV (',' idV)* ;

escrita    : 'write' '(' exps ')' ;

controlo   : cond
| ciclo
| paragem
;

cond       : 'if' '(' exp ')' '{' instrucoes '}' (('elsif' '(' exp ')' '{' instrucoes '}')* 'else' '{' instrucoes '}')? ;

ciclo      : 'while' '(' exp ')' '{' instrucoes '}'
| 'for' '(' atrib?  ';' exp ';' exp? ')' '{' instrucoes '}'
| 'do' '{' instrucoes '}' 'while' '(' exp ')'
;

paragem    : 'break'
| 'return' exp?
;

/* Identificadores ----------------------------------------------m------------ */

idF   : ID ; // ID Função
idT   : ID ; // ID Tipo
idP   : ID ; // ID ParÃ¢metro
idV   : ID ; // ID Variável
idC   : ID ; // ID Constante

conste  returns[int value]
        : idC
        | INT {$value = $INT.int;}
        | STRING
        ;

/*--------------- Lexer ------------------------------------------------------*/

ID    :	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_'|'-')* ;

OPAD  : ( '+' | '-' | '||' );

OPMUL : ( '*' | '/' | '&&' );

INT : [0-9]+ ;

WS  :   [ \t\r\n]  -> skip
;

STRING : '"' ( ESC_SEQ | ~('"') )* '"' ;

fragment
ESC_SEQ
:   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
|   UNICODE_ESC
|   OCTAL_ESC
;

fragment
OCTAL_ESC
:   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
|   '\\' ('0'..'7') ('0'..'7')
|   '\\' ('0'..'7')
;

fragment
UNICODE_ESC
:   '\\' 'u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
;
fragment
HEX_DIGIT : ('0'..'9'|'a'..'f'|'A'..'F')
;