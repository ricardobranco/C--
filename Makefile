all:
	java -jar /usr/local/lib/antlr-4.2.2-complete.jar eg13_lingC.g4
	javac eg13_lingC*.java
	java org.antlr.v4.runtime.misc.TestRig eg13_lingC programa exemplo1.c
clean:
	rm *.java *.class *.tokens
