class main2{
	public static void main(String[] args){
		int counter = 0;
		int limit = 10 + 1;
		int flag = 0;
		while(flag != 1){
			System.out.println(counter);
			counter = counter + 1;
			if(counter == limit)
				flag = 1;
			else
				flag = 0;
		}
	}
}
