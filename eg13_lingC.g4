/*
* Linguagem de Programação Imperativa tipo C
* ano letivo 13/14
*/

grammar eg13_lingC;

@header{
  import java.util.*;
  import java.lang.*;
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
    int nextID = 0;

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
           : 'define' idC exp[$table_IN]
           {
             Entry entry = new Constant();
             entry.id = $idC.text;
             entry.type = $exp.type_OUT;
             ((Constant) entry).value = $exp.value_OUT;
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
          : 'typedef' idT tipoAvancado[$table_IN,entry]
          {
            entry.type = $idT.text;
            if($table_IN.entries.containsKey(entry.type))
              System.err.println("Múltipla declaração do tipo "+entry.type);
          }
          | 'typedef' 'struct' idT
          {
            entry.id = entry.type = $idT.text;
            if($table_IN.entries.containsKey(entry.type)){
              System.err.println("Múltipla declaração do tipo "+entry.type);
            }
          }
          '{' declvariaveis[$table_IN,0,entry] '}' tipoAvancado[$table_IN,entry]
          {
            $table_IN.entries.put($tipoAvancado.entry_OUT.id,$tipoAvancado.entry_OUT);
          }
          ;

funcoes  [Table table_IN]
         : funcao[$table_IN]+
         ;

funcao  [Table table_IN]
        @after{$table_IN.removeEntries(1);}
        : cabecfuncao[$table_IN] corpofuncao[$table_IN]
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
                 if(!(entry_found instanceof Typedef)){
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

corpofuncao  [Table table_IN]
             : '{' declvariaveis[$table_IN,1,null] instrucoes[$declvariaveis.table_OUT] '}'
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
                  if(!(entry_found instanceof Typedef)){
                    System.out.println($idT.text+" não é um tipo");
                  }
                }else{
                  System.out.println("Tipo "+$idT.text+" desconhecido");
                }
              }
              listadcls[$table_IN,level,$idT.text,$struct]
              ;

listadcls  [Table table_IN, int level, String type,Entry struct]
           @init{Typedef typedef = (Typedef) struct;}
           : dcl[$table_IN,$level,$type,$struct] (',' dcl[$table_IN,$level,$type,$struct])*
           | '(' idV
           {
             Entry entry = new Variable();
             entry.id = $idV.text;
             entry.level = $level;
             entry.type = $type;

             if($struct == null){
               if($table_IN.entries.containsKey(entry.id)){
                 System.err.println("Múltipla declaração do termo "+entry.id);
               }else{
                 $table_IN.entries.put(entry.id,entry);
                 }
             }else{
               if($table_IN.entries.containsKey(entry.id)){
                 if($table_IN.entries.get(entry.id) instanceof Typedef){
                   System.err.println(entry.id+" é um tipo e não pode ser definido como variavel");
                 }
               }else{
                 if(typedef.fields.containsKey(entry.id)){
                   System.err.println("Múltipla declaração do termo "+entry.id+" na estrutura "+typedef.type);
                 }else{
                   typedef.fields.put(entry.id,entry);
                 }
               }
             }
           }
           (',' idV
           {
             Entry entryRec = new Variable();
             entryRec.id = $idV.text;
             entryRec.level = $level;
             entryRec.type = $type;
             if($struct == null){
               if($table_IN.entries.containsKey(entryRec.id)){
                 System.err.println("Múltipla declaração do termo "+entryRec.id);
               }else{
                 $table_IN.entries.put(entryRec.id,entryRec);
                 }
             }else{
               if(typedef.fields.containsKey(entryRec.id)){
                 System.err.println("Múltipla declaração do termo "+entryRec.id+" na estrutura "+typedef.type);
               }else{
                 typedef.fields.put(entryRec.id,entryRec);
               }
             }
           }
           )* ')' '=' exp[$table_IN]
           ;

dcl  [Table table_IN, int level, String type,Entry struct]
     @init{Typedef typedef = (Typedef) struct;}
     : idV
     {
       Entry entry = new Variable();
       entry.id = $idV.text;
       entry.level = $level;
       entry.type = $type;


       if($struct == null){
         if($table_IN.entries.containsKey(entry.id)){
           System.err.println("Múltipla declaração do termo "+entry.id);
         }else{
           $table_IN.entries.put(entry.id,entry);
           }
       }else{
         if($table_IN.entries.containsKey(entry.id)){
           if($table_IN.entries.get(entry.id) instanceof Typedef){
             System.err.println(entry.id+" é um tipo e não pode ser definido como variavel");
           }
         }else{
           if(typedef.fields.containsKey(entry.id)){
             System.err.println("Múltipla declaração do termo "+entry.id+" na estrutura "+typedef.type);
           }else{
             typedef.fields.put(entry.id,entry);
           }
         }
       }
     }
     ('=' exp[$table_IN])?
     | idV '[' conste[$table_IN] ']'
     {
       Entry array = new Typedef();
       array.id = "*idArray"+$table_IN.nextID;
       $table_IN.nextID++;
       array.type = $type;

       if($conste.type_OUT.equals("int")){
         ((Typedef) array).size = Integer.parseInt($conste.value_OUT);
         $table_IN.entries.put(array.id,array);
       }else{
         System.err.println($conste.value_OUT+" não é um valor númerico");
       }


       Entry entry = new Variable();
       entry.id = $idV.text;
       entry.level = $level;
       entry.type = array.id;
       if($struct == null){
         if($table_IN.entries.containsKey(entry.id)){
           System.err.println("Múltipla declaração do termo "+entry.id);
         }else{
           $table_IN.entries.put(entry.id,entry);
           }
       }else{
         if($table_IN.entries.containsKey(entry.id)){
           if($table_IN.entries.get(entry.id) instanceof Typedef){
             System.err.println(entry.id+" é um tipo e não pode ser definido como variavel");
           }
         }else{
           if(typedef.fields.containsKey(entry.id)){
             System.err.println("Múltipla declaração do termo "+entry.id+" na estrutura "+typedef.type);
           }else{
             typedef.fields.put(entry.id,entry);
           }
         }
       }
     }
     ;

tipoAvancado  [Table table_IN,Entry entry_IN]
              returns [Entry entry_OUT]
              @init{
                $entry_OUT = new Typedef();
                $entry_OUT.type = $entry_IN.id;
              }
              : ('*')? {$entry_OUT.pointer = true;}
              idT {$entry_OUT.id = $idT.text;}
              ('[' conste[table_IN] ']'
              {
                ((Typedef) $entry_OUT).size = Integer.parseInt($conste.value_OUT);
              }
              )?
              ;

/* Instruções --------------------------------------------------------------- */

instrucoes  [Table table_IN]
            : (instrucao[$table_IN] ';')+
            ;

instrucao  [Table table_IN]
           : atrib[$table_IN]
           | invocFunc[$table_IN]
           | controlo[$table_IN]
           | leitura[$table_IN]
           | escrita[$table_IN]
           ;

atrib  [Table table_IN]
       : idV
       {
         if($table_IN.entries.containsKey($idV.text)){
           Entry variavel = $table_IN.entries.get($idV.text);
           if(!(variavel instanceof Variable)){
             System.err.println($idV.text+" não é uma variavel");
           }
         }
         else{
           System.err.println($idV.text+" desconhecido");
         }
       }
       '=' exp[$table_IN];

invocFunc  [Table table_IN]
           : idF
           {
             if($table_IN.entries.containsKey($idF.text)){
               Entry variavel = $table_IN.entries.get($idF.text);
               if(!(variavel instanceof Function)){
                 System.err.println($idF.text+" não é uma função");
               }
             }
             else{
               System.err.println($idF.text+" desconhecido");
             }
           }
           '(' exps[$table_IN]? ')'
           ;

exps  [Table table_IN]
      : exp[$table_IN] ( ',' exp[$table_IN])*;

exp  [Table table_IN]
     returns [String value_OUT, String type_OUT]
     : t1 = termo[$table_IN] (OPAD t2 = termo[$table_IN]?)*
     {$value_OUT = $t1.value_OUT; $type_OUT = $t1.type_OUT;}
     ;

termo [Table table_IN]
      returns [String value_OUT, String type_OUT]
      : f1 = fator[$table_IN] (OPMUL f2 = fator[$table_IN])*
      {$value_OUT = $f1.value_OUT; $type_OUT = $f1.type_OUT;}
      ;

fator [Table table_IN]
      returns [String value_OUT, String type_OUT]
      : conste[$table_IN]
      {$value_OUT = $conste.value_OUT; $type_OUT = $conste.type_OUT;}
      | invocFunc[null]
      | '(' exp[$table_IN] ')'
      | idV '[' conste[$table_IN] ']'
      {
        if($table_IN.entries.containsKey($idV.text)){
          Entry entry = $table_IN.entries.get($idV.text);
          if(!(entry instanceof Variable)){
            System.err.println($idV.text+" não é uma variavel");
          }
        }else{
          System.err.println($idV.text+" desconhecido");
        }
      }
      ;

leitura  [Table table_IN]
         : 'read' '(' vars[$table_IN]  ')' ;

vars  [Table table_IN]
      : idV
      {
        if($table_IN.entries.containsKey($idV.text)){
          Entry entry = $table_IN.entries.get($idV.text);
          if(!(entry instanceof Variable)){
            System.err.println($idV.text+" não é uma variavel");
          }
        }else{
          System.err.println($idV.text+" desconhecido");
        }
      }
      (',' idV
      {
        if($table_IN.entries.containsKey($idV.text)){
          Entry entry = $table_IN.entries.get($idV.text);
          if(!(entry instanceof Variable)){
            System.err.println($idV.text+" não é uma variavel");
          }
        }else{
          System.err.println($idV.text+" desconhecido");
        }
      }
      )* ;

escrita  [Table table_IN]
         : 'write' '(' exps[$table_IN] ')' ;

controlo  [Table table_IN]
          : cond[$table_IN]
          | ciclo[$table_IN]
          | paragem[$table_IN]
          ;

cond  [Table table_IN]
      : 'if' '(' exp[$table_IN] ')' '{' instrucoes[$table_IN] '}' (('elsif' '(' exp[$table_IN] ')' '{' instrucoes[$table_IN] '}')* 'else' '{' instrucoes[$table_IN] '}')? ;

ciclo  [Table table_IN]
       : 'while' '(' exp[$table_IN] ')' '{' instrucoes[$table_IN] '}'
       | 'for' '(' atrib[$table_IN]?  ';' exp[$table_IN] ';' exp[$table_IN]? ')' '{' instrucoes[$table_IN] '}'
       | 'do' '{' instrucoes[$table_IN] '}' 'while' '(' exp[$table_IN] ')'
       ;

paragem  [Table table_IN]
         : 'break'
         | 'return' exp[$table_IN]?
         ;

/* Identificadores ----------------------------------------------m------------ */

idF   : ID ; // ID Função
idT   : ID ; // ID Tipo
idP   : ID ; // ID ParÃ¢metro
idV   : ID ; // ID Variável
idC   : ID ; // ID Constante

conste  [Table table_IN]
        returns [String value_OUT, String type_OUT]
        : ID {


          if($table_IN.entries.containsKey($ID.text)){
            Entry entry = $table_IN.entries.get($ID.text);
            if(entry instanceof Constant){
              $value_OUT = ((Constant) entry).value;
              $type_OUT = entry.type;
            }else{
              if(entry instanceof Variable){

              }else{
                System.err.println($ID.text+" não é uma constante ou variavel");
              }
            }
          }else{
            System.err.println($ID.text+" não definido");
          }
        }
        | INT {$value_OUT = $INT.text; $type_OUT = "int";}
        | STRING {$value_OUT = $STRING.text; $type_OUT = "char";}
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
