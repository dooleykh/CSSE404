class mainclass {
    public static void main(String[] ID) {
        
    }
}

class c extends mainclass {
    int a;
    public boolean function() {
        return true;
    }
    public boolean fun() {
        return this.function();
    }
}

class d extends c{
    public int func(int a, boolean b) {
        return 2;
    }

	public boolean function(){
		int b = this.func(2, false);
		return true;
	}

	public boolean inherit(){
		boolean result = false;
		if(this.fun())
			result = true;
		else
			result = false;
		return result;
	}
}

class f extends d{
}

class h extends f{
	public boolean func(){
		boolean l = this.inherit();
		return l;
	}
}
