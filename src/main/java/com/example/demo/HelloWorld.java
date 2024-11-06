package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloWorld {
	
	@GetMapping("/")
	public String display() {
		return "Hello World with Poll SCM on 06-10-2024 of Devsecops version v3.0";
	}

}
