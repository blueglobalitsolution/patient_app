import 'package:flutter/material.dart';

class DepartmentIconMapper {
  static IconData getIconForDepartment(String departmentName) {
    print('DEBUG: getIconForDepartment called with: "$departmentName"');
    
    if (departmentName.isEmpty) {
      print('DEBUG: Department name is empty, returning default medical_services');
      return Icons.medical_services;
    }
    
    switch (departmentName.toLowerCase()) {
      case 'cardiology':
      case 'cardiology department':
      case 'heart':
        print('DEBUG: Returning heart icon for Cardiology');
        return Icons.favorite;
      
      case 'neurology':
      case 'neurology department':
      case 'brain':
        print('DEBUG: Returning brain icon for Neurology');
        return Icons.psychology;
      
      case 'orthopedics':
      case 'orthopedics department':
      case 'bone':
      case 'orthopaedic':
        print('DEBUG: Returning bone icon for Orthopedics');
        return Icons.accessibility_new;
      
      case 'ophthalmology':
      case 'ophthalmology department':
      case 'eye':
        print('DEBUG: Returning eye icon for Ophthalmology');
        return Icons.visibility;
      
      case 'dentistry':
      case 'dental':
      case 'dental department':
      case 'tooth':
        print('DEBUG: Returning tooth icon for Dentistry');
        return Icons.sentiment_very_satisfied;
      
      case 'pulmonology':
      case 'pulmonology department':
      case 'lung':
      case 'respiratory':
        print('DEBUG: Returning lung icon for Pulmonology');
        return Icons.air;
      
      case 'nephrology':
      case 'nephrology department':
      case 'kidney':
        print('DEBUG: Returning kidney icon for Nephrology');
        return Icons.water_drop;
      
      case 'dermatology':
      case 'dermatology department':
      case 'skin':
        print('DEBUG: Returning skin icon for Dermatology');
        return Icons.face;
      
      case 'ent':
      case 'ent department':
      case 'ear, nose, throat':
      case 'otolaryngology':
      case 'ear':
        print('DEBUG: Returning ear icon for ENT');
        return Icons.hearing;
      
      case 'gastroenterology':
      case 'gastroenterology department':
      case 'stomach':
      case 'digestive':
        print('DEBUG: Returning stomach icon for Gastroenterology');
        return Icons.sick;
      
      case 'pediatrics':
      case 'pediatrics department':
      case 'pediatric':
        print('DEBUG: Returning child icon for Pediatrics');
        return Icons.child_care;
      
      case 'general surgery':
      case 'surgery':
      case 'surgical':
      case 'general':
        print('DEBUG: Returning surgery icon for General Surgery');
        return Icons.medical_services;
      
      case 'oncology':
      case 'oncology department':
      case 'cancer':
        print('DEBUG: Returning oncology icon for Oncology');
        return Icons.local_hospital;
      
      case 'gynecology':
      case 'gynecology department':
      case 'gynae':
        print('DEBUG: Returning female icon for Gynecology');
        return Icons.pregnant_woman;
      
      default:
        print('DEBUG: No specific match for "$departmentName", returning default medical_services');
        return Icons.medical_services;
    }
  }
}
