class Main{
	public static void main(String[] args){
		System.out.println( (new Two()).fun() );
	}
}

class One{
	public int a(){
		return 2;
	}

	public int fun(){
		return this.a();
	}
}

class Two extends One{
	public int a(){
		return 3;
	}
}
