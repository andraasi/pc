%{
        import java.io.*;
%}

%start program
%token <ival> NUMBER
%token <ival> IDENTIFIER
%token <ival> IF WHILE
%token SKIP THEN ELSE FI DO END DONE
%token READ WRITE BEGIN
%token ASSGNOP
%token <ival> TRUE
%token <ival> FALSE
%token AND_LOGIC
%token OR_LOGIC
%token DUAL

%left '-' '+'
%left '*' '/'
%left AND_LOGIC OR_LOGIC

%type <ival> ifThen
%type <ival> boolexp
%type <ival> command

%%

program 
        : BEGIN { 
                gen_code(I.DATA, 10); 
                mark_blank(); 
        } commands
 
END     { 
                gen_code(I.HALT, -99);
                mark_blank();
        }
        ;
commands 
        :
        | commands command ';' {mark_blank();}
        ;

ifThen 
        : IF exp { 
                $1 = reserve_loc();
                mark_blank(); 
        } THEN commands { $$ = $1; }
        ;

command 
        : SKIP

        | READ IDENTIFIER { 
                gen_code(I.READ_INT, -99); 
                gen_code(I.STORE, $2); 
        }

        | WRITE exp { 
                gen_code(I.WRITE_INT, -99); 
        }

        | IDENTIFIER ASSGNOP exp { 
                gen_code(I.STORE, $1); 
        }
        
        | IDENTIFIER IDENTIFIER DUAL exp { 
                // gen_code(I.STORE, $1); 
                // gen_code(I.STORE, $1);
        }

        | ifThen FI {
                back_patch($1 % 1000, I.JMP_FALSE, gen_label());
        }

        | ifThen ELSE { 

                $1 += 1000 * reserve_loc();
                mark_blank();
                back_patch($1 % 1000, I.JMP_FALSE, gen_label()); 

        } commands FI { 
                back_patch((int) $1 / 1000, I.GOTO, gen_label()); 
        }

        | WHILE { 
                $1 = 1000 * gen_label(); 
        } exp { 

                $1 += reserve_loc();
                mark_blank(); 

        } DO commands DONE { 

                gen_code(I.GOTO, (int) $1 / 1000);
                back_patch($1 % 1000, I.JMP_FALSE, gen_label()); 
        }
        ;

boolexp
        : TRUE { gen_code( I.LD_INT, 1 ); }
        | FALSE { gen_code( I.LD_INT, 0 ); }
        | boolexp AND_LOGIC boolexp { gen_code( I.MULT, -99 ); }
        | exp AND_LOGIC exp { gen_code( I.MULT, -99 ); }

exp 
        : NUMBER { gen_code( I.LD_INT, $1 ); }
        | IDENTIFIER { gen_code( I.LD_VAR, $1 ); }
        | exp '<' exp { gen_code( I.LT, -99 ); }
        | exp '=' exp { gen_code( I.EQ, -99 ); }
        | exp '>' exp { gen_code( I.GT, -99 ); }
        | exp '+' exp { gen_code( I.ADD, -99 ); }
        | exp '-' exp { gen_code( I.SUB, -99 ); }
        | exp '*' exp { gen_code( I.MULT, -99 ); }
        | exp '/' exp { gen_code( I.DIV, -99 ); }
        | '(' exp ')'
        | boolexp
        ;

%%


public enum I { 
        HALT, STORE, JMP_FALSE, GOTO,
        DATA, LD_INT, LD_VAR,
        READ_INT, WRITE_INT,
        LT, EQ, GT, ADD, SUB, MULT, DIV 
};

void yyerror(String s) {
        System.out.println("Err: " + s);
        System.out.println("   : " + yylval.sval);
}

static Yylex lexer;


int yylex() {
        try {
                return lexer.yylex();
        }
        catch (IOException e) {

                System.err.println("IO error : " + e);
                return -1;
        }
}

private static String text(I istr) {
        String names[] = { 
                "HALT", "STORE", "JMP_FALSE", "GOTO",
                "DATA", "LD_INT", "LD_VAR",
                "READ_INT", "WRITE_INT",
                "LT", "EQ", "GT", "ADD", "SUB", "MULT", "DIV" 
        };
        return "" + istr.ordinal() + "/" + names[istr.ordinal()];
}

private static I[] code_op = new I[999];

private static int[] code_arg = new int[999];

private static boolean[] code_mark = new boolean[999];

private static int stC = 0;

public static void print_code() {

        I istr; int arg;
        int i; 

        for (i = 0; i < stC; ++i) {

                istr = code_op[i];
                arg = code_arg[i];
                System.out.println("" + (i) + "-" + text(istr) + " " + arg);

                if (code_mark[i]) {
                        System.out.println();
                }
        }
}

public static void gen_code(I istr, int arg) {
        code_op[stC] = istr;
        code_arg[stC] = arg;
        stC++;
}

public static void mark_blank() {
        code_mark[stC-1]=true;
}

public static int gen_label() {
        return stC;
}

public static int reserve_loc() {
        return stC++;
}

public static void back_patch(int addr, I istr, int arg) {
        code_op[addr] = istr;
        code_arg[addr] = arg;
}



public static void main(String args[]) {
        
        Parser par = new Parser();
        lexer = new Yylex(new InputStreamReader(System.in), par);
        par.yyparse();
        print_code();
}
