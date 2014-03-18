public static int fib(int arg){
	if(arg <= 2){
		return 1;
	}else{
		return fib(arg-1) + fib(arg-2);
	}
}

class caSe{
	public static void main(String[] args){
		fib(200);
		// this is a terrible idea
	}
}
